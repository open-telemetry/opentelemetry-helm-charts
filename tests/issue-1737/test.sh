#!/usr/bin/env bash
set -euo pipefail

helm_bin=${HELM:-helm}
fixture_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$fixture_dir/../.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/tests" "$work_dir/charts"
cp -R "$fixture_dir" "$work_dir/tests/issue-1737"
cp -R "$repo_dir/charts/opentelemetry-collector" "$work_dir/charts/opentelemetry-collector"
fixture_dir="$work_dir/tests/issue-1737"
cat > "$work_dir/charts/opentelemetry-collector/templates/fixture-configmap.yaml" <<'EOF'
{{ include "umbrella.configmap" . }}
EOF

"$helm_bin" dependency build "$fixture_dir/charts/wrapper"
"$helm_bin" dependency build "$fixture_dir"
render() {
  "$helm_bin" template repro "$fixture_dir" -f "$fixture_dir/values.yaml" "$@"
}

base=$(render)
changed=$(render --set-string global.externalConfig='receivers: { otlp: { protocols: { http: {} } } }')
base_checksum=$(printf '%s\n' "$base" | sed -n 's/.*checksum\/config: //p' | head -n1)
changed_checksum=$(printf '%s\n' "$changed" | sed -n 's/.*checksum\/config: //p' | head -n1)
test -n "$base_checksum"
if test "$base_checksum" = "$changed_checksum"; then
  echo "checksum did not change when the parent ConfigMap template changed: $base_checksum" >&2
  exit 1
fi
printf '%s\n' "$base" | grep -q 'name: external-collector-config'
printf '%s\n' "$base" | grep -q '^# Source: issue-1737/templates/configmap.yaml'

relative_args=(
  --set wrapper.opentelemetry-collector.configMap.existingTemplate=null
  --set wrapper.opentelemetry-collector.configMap.existingPath=fixture-configmap.yaml
)
relative=$(render "${relative_args[@]}")
relative_changed=$(render "${relative_args[@]}" \
  --set-string global.externalConfig='receivers: { otlp: { protocols: { http: {} } } }')
relative_checksum=$(printf '%s\n' "$relative" | sed -n 's/.*checksum\/config: //p' | head -n1)
relative_changed_checksum=$(printf '%s\n' "$relative_changed" | sed -n 's/.*checksum\/config: //p' | head -n1)
test -n "$relative_checksum"
if test "$relative_checksum" = "$relative_changed_checksum"; then
  echo 'relative ConfigMap template checksum did not follow its config' >&2
  exit 1
fi

if render --set wrapper.opentelemetry-collector.configMap.existingPath=configmap.yaml \
  --set wrapper.opentelemetry-collector.configMap.existingTemplate=umbrella.configmap >/dev/null 2>&1; then
  echo 'expected existingPath and existingTemplate to be mutually exclusive' >&2
  exit 1
fi

if render --set wrapper.opentelemetry-collector.configMap.create=true \
  --set wrapper.opentelemetry-collector.configMap.existingName=null >"$work_dir/invalid.out" 2>&1; then
  echo 'expected existingTemplate to require an externally created ConfigMap' >&2
  exit 1
fi
grep -q 'Cannot set configMap.existingTemplate when configMap.create is true' "$work_dir/invalid.out"

for mode in deployment daemonset statefulset; do
  "$helm_bin" template repro "$repo_dir/charts/opentelemetry-collector" \
    --set image.repository=otel/opentelemetry-collector-contrib \
    --set mode="$mode" | grep -q 'checksum/config:'
done
printf 'issue #1737 regression passed (Helm %s)\n' "$("$helm_bin" version --short)"
