#!/usr/bin/env bash

# Fails when the operator feature gates exposed by this chart through
# manager.featureGatesMap drift from the gates the operator actually registers
# at the chart's appVersion. A new operator release that adds or drops a gate
# should not be able to land here without the schema being updated to match.

set -Eeuo pipefail
IFS=$'\n\t'

CHART_YAML="${CHART_YAML:-charts/opentelemetry-operator/Chart.yaml}"
SCHEMA_FILE="${SCHEMA_FILE:-charts/opentelemetry-operator/values.schema.json}"
# Set FEATUREGATE_FILE to read the operator gates from a local file instead of
# downloading them; the tests use it to run offline.
FEATUREGATE_FILE="${FEATUREGATE_FILE:-}"

fail() {
  printf 'check-operator-feature-gates: %s\n' "$1" >&2
  exit 1
}

operator_version() {
  if [[ -n "${OPERATOR_APP_VERSION:-}" ]]; then
    printf '%s\n' "${OPERATOR_APP_VERSION}"
    return
  fi

  local version
  version="$(sed -n 's/^appVersion: //p' "${CHART_YAML}")"
  [[ -n "${version}" ]] || fail "could not read appVersion from ${CHART_YAML}"
  printf '%s\n' "${version}"
}

operator_source() {
  local version="$1"

  if [[ -n "${FEATUREGATE_FILE}" ]]; then
    cat "${FEATUREGATE_FILE}"
    return
  fi

  local url="https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v${version}/pkg/featuregate/featuregate.go"
  curl -sSfL "${url}" || fail "could not download ${url}"
}

# Users can only toggle alpha and beta gates; stable gates are locked on and are
# removed from the operator, so the chart only tracks alpha and beta ones.
registered_gates() {
  awk '
    /MustRegister\(/ { in_block = 1; gate_id = ""; stage = ""; next }
    in_block && gate_id == "" && /"/ {
      if (match($0, /"[^"]+"/)) { gate_id = substr($0, RSTART + 1, RLENGTH - 2) }
      next
    }
    in_block && /featuregate\.Stage/ {
      if (match($0, /Stage[A-Za-z]+/)) { stage = substr($0, RSTART + 5, RLENGTH - 5) }
    }
    in_block && gate_id != "" && stage != "" {
      if (stage == "Alpha" || stage == "Beta") { print gate_id }
      in_block = 0
    }
  ' | sort -u
}

schema_gates() {
  jq -r '.properties.manager.properties.featureGatesMap.properties | keys[]' "${SCHEMA_FILE}" | sort -u
}

main() {
  local version
  version="$(operator_version)"

  local operator_gates chart_gates
  operator_gates="$(operator_source "${version}" | registered_gates)"
  chart_gates="$(schema_gates)"

  [[ -n "${operator_gates}" ]] || fail "found no feature gates in the operator source for v${version}; the upstream file or its format may have changed"

  local missing extra
  missing="$(comm -23 <(printf '%s\n' "${operator_gates}") <(printf '%s\n' "${chart_gates}"))"
  extra="$(comm -13 <(printf '%s\n' "${operator_gates}") <(printf '%s\n' "${chart_gates}"))"

  if [[ -z "${missing}" && -z "${extra}" ]]; then
    printf 'feature gates are in sync with operator v%s\n' "${version}"
    return 0
  fi

  printf 'feature gates are out of sync with operator v%s:\n' "${version}" >&2
  if [[ -n "${missing}" ]]; then
    printf '  missing from values.schema.json: %s\n' "$(printf '%s ' ${missing})" >&2
  fi
  if [[ -n "${extra}" ]]; then
    printf '  no longer registered by the operator: %s\n' "$(printf '%s ' ${extra})" >&2
  fi
  exit 1
}

main "$@"
