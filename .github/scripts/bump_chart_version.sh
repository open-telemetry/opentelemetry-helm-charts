#!/usr/bin/env bash
set -euo pipefail

# bump_chart_version.sh <chart_yaml_path> <bump_type> [prerelease]
# - bump_type: patch|minor|major
# - optional prerelease string (e.g., rc.1) or via PRERELEASE env

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <charts/.../Chart.yaml> <patch|minor|major> [prerelease]" >&2
  exit 64
fi

chart_yaml="$1"
bump_type="$2"
prerelease_part="${3:-${PRERELEASE:-}}"

if [[ ! -f "$chart_yaml" ]]; then
  echo "error: file not found: $chart_yaml" >&2
  exit 66
fi

read_current_version() {
  if command -v yq >/dev/null 2>&1; then
    yq e '.version' "$chart_yaml"
  else
    awk '/^version:/ {print $2; exit}' "$chart_yaml"
  fi
}

write_new_version() {
  local newv="$1"
  if command -v yq >/dev/null 2>&1; then
    yq e ".version = \"${newv}\"" -i "$chart_yaml"
  else
    if grep -q '^[[:space:]]*version:' "$chart_yaml"; then
      sed -i -E "s/^([[:space:]]*version:[[:space:]]*).*/\1${newv}/" "$chart_yaml"
    else
      echo "version: ${newv}" >> "$chart_yaml"
    fi
  fi
}

strip_prerelease_build() {
  printf '%s' "$1" | sed -E 's/[-+].*$//'
}

cur=$(read_current_version)
if [[ -z "$cur" || "$cur" == "null" ]]; then
  echo "error: could not read current version from $chart_yaml" >&2
  exit 65
fi

base=$(strip_prerelease_build "$cur")
IFS='.' read -r major minor patch <<< "$base"
major=${major:-0}
minor=${minor:-0}
patch=${patch:-0}

case "$bump_type" in
  major)
    major=$((major+1)); minor=0; patch=0 ;;
  minor)
    minor=$((minor+1)); patch=0 ;;
  patch)
    patch=$((patch+1)) ;;
  *)
    echo "error: invalid bump_type '$bump_type' (expected major|minor|patch)" >&2
    exit 64 ;;
esac

newv="${major}.${minor}.${patch}"
if [[ -n "$prerelease_part" ]]; then
  newv+="-${prerelease_part}"
fi

write_new_version "$newv"
echo "$newv"

#!/usr/bin/env bash
set -euo pipefail

# bump_chart_version.sh <chart_yaml_path> <bump_type> [prerelease]
# - bump_type: patch|minor|major
# - optional prerelease string (e.g., rc.1) or via PRERELEASE env
# Requires: yq (v4). Falls back to sed if yq not found (best-effort).

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <charts/.../Chart.yaml> <patch|minor|major> [prerelease]" >&2
  exit 64
fi

chart_yaml="$1"
bump_type="$2"
prerelease_part="${3:-${PRERELEASE:-}}"

if [[ ! -f "$chart_yaml" ]]; then
  echo "error: file not found: $chart_yaml" >&2
  exit 66
fi

read_current_version() {
  if command -v yq >/dev/null 2>&1; then
    yq e '.version' "$chart_yaml"
  else
    # naive fallback: grep first 'version:' at column 0
    awk '/^version:/ {print $2; exit}' "$chart_yaml"
  fi
}

write_new_version() {
  local newv="$1"
  if command -v yq >/dev/null 2>&1; then
    yq e ".version = \"${newv}\"" -i "$chart_yaml"
  else
    # sed inline replacement of top-level version
    # keep indentation as-is if any
    if grep -q '^[[:space:]]*version:' "$chart_yaml"; then
      sed -i -E "s/^([[:space:]]*version:[[:space:]]*).*/\\1${newv}/" "$chart_yaml"
    else
      echo "version: ${newv}" >> "$chart_yaml"
    fi
  fi
}

strip_prerelease_build() {
  # remove -pre and +build metadata
  printf '%s' "$1" | sed -E 's/[-+].*$//'
}

cur=$(read_current_version)
if [[ -z "$cur" || "$cur" == "null" ]]; then
  echo "error: could not read current version from $chart_yaml" >&2
  exit 65
fi

base=$(strip_prerelease_build "$cur")
IFS='.' read -r major minor patch <<< "$base"
major=${major:-0}
minor=${minor:-0}
patch=${patch:-0}

case "$bump_type" in
  major)
    major=$((major+1)); minor=0; patch=0 ;;
  minor)
    minor=$((minor+1)); patch=0 ;;
  patch)
    patch=$((patch+1)) ;;
  *)
    echo "error: invalid bump_type '$bump_type' (expected major|minor|patch)" >&2
    exit 64 ;;
esac

newv="${major}.${minor}.${patch}"
if [[ -n "$prerelease_part" ]]; then
  newv+="-${prerelease_part}"
fi

write_new_version "$newv"
echo "$newv"


