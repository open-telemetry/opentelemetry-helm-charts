#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/.github/scripts/update-chart-app-version.sh"
TEST_TMP_ROOT="${ROOT_DIR}/tmp/update-chart-app-version"

fail() {
	printf 'ERROR: %s\n' "$1" >&2
	exit 1
}

assert_equals() {
	local expected="$1"
	local actual="$2"
	local message="$3"

	if [[ "${expected}" != "${actual}" ]]; then
		printf 'FAIL: %s\n' "${message}" >&2
		printf '  expected: %s\n' "${expected}" >&2
		printf '  actual:   %s\n' "${actual}" >&2
		exit 1
	fi
}

read_yaml_field() {
	local file_path="$1"
	local field_name="$2"

	sed -n "s/^${field_name}: \\(.*\\)$/\\1/p" "${file_path}"
}

read_output_field() {
	local output_path="$1"
	local field_name="$2"

	sed -n "s/^${field_name}=\\(.*\\)$/\\1/p" "${output_path}" | tail -n 1
}

run_case() {
	local name="$1"
	local fixture="$2"
	local release_tag="$3"
	local chart_name="$4"
	local upstream_repository="$5"
	local release_tag_prefix="$6"
	local app_version_prefix="$7"
	local branch_prefix="$8"
	local version_policy="$9"
	local approvers="${10}"
	local pr_title_template="${11}"
	local pr_body_template="${12}"
	local expected_changed="${13}"
	local expected_branch_name="${14}"
	local expected_chart_version="${15}"
	local expected_app_version="${16}"

	local case_dir="${TEST_TMP_ROOT}/${name}"
	local chart_yaml_path="${ROOT_DIR}/charts/${chart_name}/Chart.yaml"
	local backup_path="${case_dir}/Chart.yaml.original"
	local output_path=""

	rm -rf "${case_dir}"
	mkdir -p "${case_dir}"
	cp "${chart_yaml_path}" "${backup_path}"
	cp "${ROOT_DIR}/${fixture}" "${chart_yaml_path}"

	output_path="$(mktemp)"

	cleanup_case() {
		cp "${backup_path}" "${chart_yaml_path}"
		rm -f "${output_path}"
	}

	trap cleanup_case RETURN

	(
		cd "${ROOT_DIR}"
		GITHUB_OUTPUT="${output_path}" \
			RELEASE_TAG="${release_tag}" \
			CHART_NAME="${chart_name}" \
			CHART_ROOT="charts/${chart_name}" \
			CHART_YAML="charts/${chart_name}/Chart.yaml" \
			STAGE_PATH="charts/${chart_name}" \
			UPSTREAM_REPOSITORY="${upstream_repository}" \
			RELEASE_TAG_PREFIX="${release_tag_prefix}" \
			APP_VERSION_PREFIX="${app_version_prefix}" \
			BRANCH_PREFIX="${branch_prefix}" \
			VERSION_POLICY="${version_policy}" \
			APPROVERS="${approvers}" \
			PR_TITLE_TEMPLATE="${pr_title_template}" \
			PR_BODY_TEMPLATE="${pr_body_template}" \
			POST_UPDATE_ACTION="none" \
			bash "${SCRIPT_PATH}" >/dev/null
	)

	assert_equals "${expected_changed}" "$(read_output_field "${output_path}" "changed")" "${name}: changed output"
	assert_equals "${expected_branch_name}" "$(read_output_field "${output_path}" "branch_name")" "${name}: branch_name output"
	assert_equals "${expected_chart_version}" "$(read_yaml_field "${chart_yaml_path}" "version")" "${name}: chart version"
	assert_equals "${expected_app_version}" "$(read_yaml_field "${chart_yaml_path}" "appVersion")" "${name}: appVersion"

	cleanup_case
	trap - RETURN
}

main() {
	rm -rf "${TEST_TMP_ROOT}"
	mkdir -p "${TEST_TMP_ROOT}"

	run_case \
		"obi-noop-same-app-version" \
		".github/scripts/testdata/update-chart-app-version/obi-chart-0.8.1-app-v0.8.0.yaml" \
		"v0.8.0" \
		"opentelemetry-ebpf-instrumentation" \
		"open-telemetry/opentelemetry-ebpf-instrumentation" \
		"v" \
		"v" \
		"obi" \
		"mirror-upstream-without-prefix" \
		"@open-telemetry/ebpf-instrumentation-approvers" \
		"Update OBI chart to use latest OBI version: {{ release_tag }}" \
		$'{{ release_url }}\n\ncc {{ approvers }}' \
		"false" \
		"otelbot/obi-0.8.1" \
		"0.8.1" \
		"v0.8.0"

	run_case \
		"obi-patch-bump-existing-chart-line" \
		".github/scripts/testdata/update-chart-app-version/obi-chart-0.8.1-app-v0.8.0.yaml" \
		"v0.8.1" \
		"opentelemetry-ebpf-instrumentation" \
		"open-telemetry/opentelemetry-ebpf-instrumentation" \
		"v" \
		"v" \
		"obi" \
		"mirror-upstream-without-prefix" \
		"@open-telemetry/ebpf-instrumentation-approvers" \
		"Update OBI chart to use latest OBI version: {{ release_tag }}" \
		$'{{ release_url }}\n\ncc {{ approvers }}' \
		"true" \
		"otelbot/obi-0.8.2" \
		"0.8.2" \
		"v0.8.1"

	run_case \
		"obi-initialize-to-upstream-line" \
		".github/scripts/testdata/update-chart-app-version/obi-chart-0.7.9-app-v0.7.8.yaml" \
		"v0.8.1" \
		"opentelemetry-ebpf-instrumentation" \
		"open-telemetry/opentelemetry-ebpf-instrumentation" \
		"v" \
		"v" \
		"obi" \
		"mirror-upstream-without-prefix" \
		"@open-telemetry/ebpf-instrumentation-approvers" \
		"Update OBI chart to use latest OBI version: {{ release_tag }}" \
		$'{{ release_url }}\n\ncc {{ approvers }}' \
		"true" \
		"otelbot/obi-0.8.1" \
		"0.8.1" \
		"v0.8.1"

	run_case \
		"ta-noop-same-app-version" \
		".github/scripts/testdata/update-chart-app-version/ta-chart-0.127.2-app-0.126.0.yaml" \
		"v0.126.0" \
		"opentelemetry-target-allocator" \
		"open-telemetry/opentelemetry-operator" \
		"v" \
		"" \
		"ta" \
		"patch-bump" \
		"@atoulme" \
		"Update target allocator chart to use latest target allocator version: {{ release_tag }}" \
		$'{{ release_url }}\n\ncc {{ approvers }}' \
		"false" \
		"otelbot/ta-0.127.2" \
		"0.127.2" \
		"0.126.0"

	run_case \
		"ta-patch-bump-same-minor-line" \
		".github/scripts/testdata/update-chart-app-version/ta-chart-0.127.2-app-0.126.0.yaml" \
		"v0.126.1" \
		"opentelemetry-target-allocator" \
		"open-telemetry/opentelemetry-operator" \
		"v" \
		"" \
		"ta" \
		"patch-bump" \
		"@atoulme" \
		"Update target allocator chart to use latest target allocator version: {{ release_tag }}" \
		$'{{ release_url }}\n\ncc {{ approvers }}' \
		"true" \
		"otelbot/ta-0.127.3" \
		"0.127.3" \
		"0.126.1"

	run_case \
		"ta-jump-to-higher-minor-line" \
		".github/scripts/testdata/update-chart-app-version/ta-chart-0.127.2-app-0.126.0.yaml" \
		"v0.150.0" \
		"opentelemetry-target-allocator" \
		"open-telemetry/opentelemetry-operator" \
		"v" \
		"" \
		"ta" \
		"patch-bump" \
		"@atoulme" \
		"Update target allocator chart to use latest target allocator version: {{ release_tag }}" \
		$'{{ release_url }}\n\ncc {{ approvers }}' \
		"true" \
		"otelbot/ta-0.150.0" \
		"0.150.0" \
		"0.150.0"

	rm -rf "${TEST_TMP_ROOT}"
	printf 'PASS\n'
}

main "$@"
