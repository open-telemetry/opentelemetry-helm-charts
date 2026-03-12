#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

readonly CHART_NAME="opentelemetry-ebpf-instrumentation"
readonly CHART_PATH="charts/${CHART_NAME}/Chart.yaml"
readonly UPSTREAM_REPOSITORY="${UPSTREAM_REPOSITORY:-open-telemetry/opentelemetry-ebpf-instrumentation}"
readonly RELEASE_APPROVERS="@open-telemetry/ebpf-instrumentation-approvers"

log() {
  local message="$1"

  printf '%s\n' "${message}"
}

fail() {
  local message="$1"

  printf 'ERROR: %s\n' "${message}" >&2
  exit 1
}

require_command() {
  local command_name="$1"

  command -v "${command_name}" >/dev/null 2>&1 \
    || fail "Required command not found: ${command_name}"
}

require_file() {
  local file_path="$1"

  [[ -f "${file_path}" ]] \
    || fail "Required file not found: ${file_path}"
}

set_output() {
  local key="$1"
  local value="$2"

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "${key}" "${value}" >> "${GITHUB_OUTPUT}"
  fi
}

set_multiline_output() {
  local key="$1"
  local value="$2"

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      printf '%s<<__EOF__\n' "${key}"
      printf '%s\n' "${value}"
      printf '__EOF__\n'
    } >> "${GITHUB_OUTPUT}"
  fi
}

current_field_value() {
  local field_name="$1"
  sed -n "s/^${field_name}: \\(.*\\)$/\\1/p" "${CHART_PATH}"
}

resolve_release_tag() {
  local release_tag="${RELEASE_TAG:-}"

  if [[ -z "${release_tag}" ]]; then
    release_tag="$(gh api "repos/${UPSTREAM_REPOSITORY}/releases/latest" --jq '.tag_name')"
  fi

  [[ -n "${release_tag}" ]] \
    || fail "Failed to resolve an upstream OBI release tag"

  printf '%s\n' "${release_tag}"
}

set_default_outputs() {
  local release_tag="$1"
  local release_url="$2"

  set_output "changed" "false"
  set_output "release_tag" "${release_tag}"
  set_output "branch_name" "obi-${release_tag}"
  set_output "commit_message" "Update OBI chart to ${release_tag}"
  set_output "pr_title" "Update OBI chart to use latest OBI version: ${release_tag}"
  set_multiline_output "pr_body" "${release_url}

cc ${RELEASE_APPROVERS}"
}

update_chart_metadata() {
  local release_tag="$1"
  local release_version="$2"
  local temp_file=""

  temp_file="$(mktemp)"
  awk -v release_version="${release_version}" -v release_tag="${release_tag}" '
    /^version: / { print "version: " release_version; next }
    /^appVersion: / { print "appVersion: " release_tag; next }
    { print }
  ' "${CHART_PATH}" > "${temp_file}"
  mv "${temp_file}" "${CHART_PATH}"
}

render_examples() {
  make generate-examples CHARTS="${CHART_NAME}"
}

main() {
  local release_tag=""
  local release_version=""
  local release_url=""
  local current_chart_version=""
  local current_app_version=""

  require_command gh
  require_command git
  require_command make
  require_command awk
  require_command mktemp
  require_file "${CHART_PATH}"

  release_tag="$(resolve_release_tag)"
  release_version="${release_tag#v}"
  release_url="https://github.com/${UPSTREAM_REPOSITORY}/releases/tag/${release_tag}"
  current_chart_version="$(current_field_value "version")"
  current_app_version="$(current_field_value "appVersion")"

  set_default_outputs "${release_tag}" "${release_url}"

  if [[ "${current_chart_version}" == "${release_version}" && "${current_app_version}" == "${release_tag}" ]]; then
    log "Chart already points at ${release_tag}; nothing to do."
    return 0
  fi

  update_chart_metadata "${release_tag}" "${release_version}"
  render_examples

  if git diff --quiet -- "charts/${CHART_NAME}"; then
    log "No chart changes were produced for ${release_tag}; nothing to do."
    return 0
  fi

  set_output "changed" "true"
}

main "$@"
