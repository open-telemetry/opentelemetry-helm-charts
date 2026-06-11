#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="${ROOT_DIR}/.github/scripts/check-operator-feature-gates.sh"
DATA_DIR="${ROOT_DIR}/.github/scripts/testdata/check-operator-feature-gates"

passed=0

run_checker() {
  local featuregate_file="$1"
  local schema_file="$2"

  FEATUREGATE_FILE="${featuregate_file}" \
  SCHEMA_FILE="${schema_file}" \
  OPERATOR_APP_VERSION="0.0.0" \
    bash "${CHECKER}"
}

expect_in_sync() {
  local description="$1"
  local featuregate_file="$2"
  local schema_file="$3"

  if run_checker "${featuregate_file}" "${schema_file}" >/dev/null 2>&1; then
    printf 'ok   - %s\n' "${description}"
    passed=$((passed + 1))
  else
    printf 'FAIL - %s (expected the checker to pass)\n' "${description}" >&2
    exit 1
  fi
}

expect_drift() {
  local description="$1"
  local featuregate_file="$2"
  local schema_file="$3"

  if run_checker "${featuregate_file}" "${schema_file}" >/dev/null 2>&1; then
    printf 'FAIL - %s (expected the checker to report drift)\n' "${description}" >&2
    exit 1
  else
    printf 'ok   - %s\n' "${description}"
    passed=$((passed + 1))
  fi
}

main() {
  local work_dir
  work_dir="$(mktemp -d)"
  trap "rm -rf '${work_dir}'" EXIT

  local schema_in_sync="${DATA_DIR}/schema-insync.json"
  local gates_path='.properties.manager.properties.featureGatesMap.properties'

  expect_in_sync "alpha and beta gates match the schema" \
    "${DATA_DIR}/featuregate-insync.go" "${schema_in_sync}"

  local schema_missing="${work_dir}/schema-missing.json"
  jq "del(${gates_path}[\"demo.beta.one\"])" "${schema_in_sync}" > "${schema_missing}"
  expect_drift "schema is missing a gate the operator registers" \
    "${DATA_DIR}/featuregate-insync.go" "${schema_missing}"

  local schema_extra="${work_dir}/schema-extra.json"
  jq "${gates_path}[\"demo.removed.one\"] = {\"type\":\"boolean\",\"default\":false}" \
    "${schema_in_sync}" > "${schema_extra}"
  expect_drift "schema keeps a gate the operator dropped" \
    "${DATA_DIR}/featuregate-insync.go" "${schema_extra}"

  expect_drift "operator source parses to no gates" \
    "${DATA_DIR}/featuregate-empty.go" "${schema_in_sync}"

  printf '\n%d checks passed\n' "${passed}"
}

main "$@"
