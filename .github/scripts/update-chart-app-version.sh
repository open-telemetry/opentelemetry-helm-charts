#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

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

require_directory() {
  local directory_path="$1"

  [[ -d "${directory_path}" ]] \
    || fail "Required directory not found: ${directory_path}"
}

require_env() {
  local variable_name="$1"

  [[ -n "${!variable_name+x}" ]] \
    || fail "Required environment variable not set: ${variable_name}"
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
  local delimiter=""

  delimiter="__${key}_$$_${RANDOM}__"

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
      printf '%s<<%s\n' "${key}" "${delimiter}"
      printf '%s\n' "${value}"
      printf '%s\n' "${delimiter}"
    } >> "${GITHUB_OUTPUT}"
  fi
}

current_field_value() {
  local field_name="$1"

  sed -n "s/^${field_name}: \\(.*\\)$/\\1/p" "${CHART_YAML}"
}

strip_prefix() {
  local value="$1"
  local prefix="$2"

  if [[ -n "${prefix}" && "${value}" == "${prefix}"* ]]; then
    printf '%s\n' "${value#"$prefix"}"
    return 0
  fi

  printf '%s\n' "${value}"
}

validate_release_tag() {
  local release_tag="$1"
  local expected_prefix="$2"
  local tag_pattern=""

  if [[ -n "${expected_prefix}" ]]; then
    tag_pattern="^${expected_prefix}[0-9]+\\.[0-9]+\\.[0-9]+$"
  else
    tag_pattern="^[0-9]+\\.[0-9]+\\.[0-9]+$"
  fi

  [[ "${release_tag}" =~ ${tag_pattern} ]] \
    || fail "Release tag does not match expected pattern: ${release_tag}"
}

validate_chart_path() {
  local path_value="$1"
  local path_kind="$2"

  [[ "${path_value}" == charts/* ]] \
    || fail "${path_kind} must be under charts/: ${path_value}"
}

resolve_release_tag() {
  local release_tag="${RELEASE_TAG:-}"

  if [[ -z "${release_tag}" ]]; then
    release_tag="$(gh api "repos/${UPSTREAM_REPOSITORY}/releases/latest" --jq '.tag_name')"
  fi

  [[ -n "${release_tag}" ]] \
    || fail "Failed to resolve upstream release tag for ${UPSTREAM_REPOSITORY}"

  validate_release_tag "${release_tag}" "${RELEASE_TAG_PREFIX}"

  printf '%s\n' "${release_tag}"
}

render_template() {
  local template="$1"
  local rendered=""

  rendered="${template//\{\{ release_tag \}\}/${RESOLVED_RELEASE_TAG}}"
  rendered="${rendered//\{\{ release_url \}\}/${RELEASE_URL}}"
  rendered="${rendered//\{\{ approvers \}\}/${APPROVERS}}"
  rendered="${rendered//\{\{ chart_name \}\}/${CHART_NAME}}"

  printf '%s\n' "${rendered}"
}

increment_patch_version() {
  local version="$1"
  local major=""
  local minor=""
  local patch=""

  IFS='.' read -r major minor patch <<< "${version}"

  [[ -n "${major}" && -n "${minor}" && -n "${patch}" ]] \
    || fail "Invalid semver value for patch bump: ${version}"

  printf '%s.%s.%s\n' "${major}" "${minor}" "$((patch + 1))"
}

desired_app_version() {
  if [[ -n "${APP_VERSION_PREFIX}" ]]; then
    printf '%s%s\n' "${APP_VERSION_PREFIX}" "${NORMALIZED_RELEASE_VERSION}"
    return 0
  fi

  printf '%s\n' "${NORMALIZED_RELEASE_VERSION}"
}

desired_chart_version() {
  local current_app_version="$1"
  local current_chart_version="$2"
  local next_app_version="$3"

  case "${VERSION_POLICY}" in
    mirror-upstream-without-prefix)
      printf '%s\n' "${NORMALIZED_RELEASE_VERSION}"
      ;;
    patch-bump)
      if [[ "${current_app_version}" == "${next_app_version}" ]]; then
        printf '%s\n' "${current_chart_version}"
        return 0
      fi

      increment_patch_version "${current_chart_version}"
      ;;
    *)
      fail "Unsupported VERSION_POLICY: ${VERSION_POLICY}"
      ;;
  esac
}

update_chart_metadata() {
  local next_chart_version="$1"
  local next_app_version="$2"
  local temp_file=""

  temp_file="$(mktemp)"
  awk -v next_chart_version="${next_chart_version}" -v next_app_version="${next_app_version}" '
    /^version: / { print "version: " next_chart_version; next }
    /^appVersion: / { print "appVersion: " next_app_version; next }
    { print }
  ' "${CHART_YAML}" > "${temp_file}"
  mv "${temp_file}" "${CHART_YAML}"
}

run_post_update_action() {
  # Keep post-update behavior on a small allowlist. This workflow runs with
  # write-capable bot credentials, so callers must not be able to provide
  # arbitrary shell commands here.
  case "${POST_UPDATE_ACTION}" in
    none)
      return 0
      ;;
    generate-examples)
      make generate-examples CHARTS="${CHART_NAME}"
      ;;
    *)
      fail "Unsupported POST_UPDATE_ACTION: ${POST_UPDATE_ACTION}"
      ;;
  esac
}

set_default_outputs() {
  local pr_title=""
  local pr_body=""

  pr_title="$(render_template "${PR_TITLE_TEMPLATE}")"
  pr_body="$(render_template "${PR_BODY_TEMPLATE}")"

  set_output "changed" "false"
  set_output "release_tag" "${RESOLVED_RELEASE_TAG}"
  set_output "branch_name" "${BRANCH_PREFIX}-${RESOLVED_RELEASE_TAG}"
  set_output "commit_message" "${pr_title}"
  set_output "stage_path" "${STAGE_PATH}"
  set_output "pr_title" "${pr_title}"
  set_multiline_output "pr_body" "${pr_body}"
}

main() {
  local current_chart_version=""
  local current_app_version=""
  local next_chart_version=""
  local next_app_version=""

  require_command gh
  require_command git
  require_command make
  require_command awk
  require_command bash
  require_command mktemp
  require_command sed

  require_env CHART_NAME
  require_env CHART_YAML
  require_env CHART_ROOT
  require_env STAGE_PATH
  require_env UPSTREAM_REPOSITORY
  require_env RELEASE_TAG_PREFIX
  require_env APP_VERSION_PREFIX
  require_env BRANCH_PREFIX
  require_env VERSION_POLICY
  require_env APPROVERS
  require_env PR_TITLE_TEMPLATE
  require_env PR_BODY_TEMPLATE
  require_env POST_UPDATE_ACTION

  validate_chart_path "${CHART_ROOT}" "CHART_ROOT"
  validate_chart_path "${CHART_YAML}" "CHART_YAML"
  validate_chart_path "${STAGE_PATH}" "STAGE_PATH"
  require_directory "${CHART_ROOT}"
  require_file "${CHART_YAML}"

  RESOLVED_RELEASE_TAG="$(resolve_release_tag)"
  NORMALIZED_RELEASE_VERSION="$(strip_prefix "${RESOLVED_RELEASE_TAG}" "${RELEASE_TAG_PREFIX}")"
  RELEASE_URL="https://github.com/${UPSTREAM_REPOSITORY}/releases/tag/${RESOLVED_RELEASE_TAG}"

  current_chart_version="$(current_field_value "version")"
  current_app_version="$(current_field_value "appVersion")"

  next_app_version="$(desired_app_version)"
  next_chart_version="$(desired_chart_version "${current_app_version}" "${current_chart_version}" "${next_app_version}")"

  set_default_outputs

  if [[ "${current_chart_version}" == "${next_chart_version}" && "${current_app_version}" == "${next_app_version}" ]]; then
    log "Chart already points at ${RESOLVED_RELEASE_TAG}; nothing to do."
    return 0
  fi

  update_chart_metadata "${next_chart_version}" "${next_app_version}"
  run_post_update_action

  if git diff --quiet -- "${STAGE_PATH}"; then
    log "No staged changes were produced for ${RESOLVED_RELEASE_TAG}; nothing to do."
    return 0
  fi

  set_output "changed" "true"
}

declare CHART_NAME="${CHART_NAME:-}"
declare CHART_ROOT="${CHART_ROOT:-}"
declare CHART_YAML="${CHART_YAML:-}"
declare STAGE_PATH="${STAGE_PATH:-}"
declare UPSTREAM_REPOSITORY="${UPSTREAM_REPOSITORY:-}"
declare RELEASE_TAG_PREFIX="${RELEASE_TAG_PREFIX:-}"
declare APP_VERSION_PREFIX="${APP_VERSION_PREFIX:-}"
declare BRANCH_PREFIX="${BRANCH_PREFIX:-}"
declare VERSION_POLICY="${VERSION_POLICY:-}"
declare APPROVERS="${APPROVERS:-}"
declare PR_TITLE_TEMPLATE="${PR_TITLE_TEMPLATE:-}"
declare PR_BODY_TEMPLATE="${PR_BODY_TEMPLATE:-}"
declare POST_UPDATE_ACTION="${POST_UPDATE_ACTION:-}"
declare RELEASE_URL=""
declare RESOLVED_RELEASE_TAG=""
declare NORMALIZED_RELEASE_VERSION=""

main "$@"
