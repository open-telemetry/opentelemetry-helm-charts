#!/usr/bin/env bash
set -euo pipefail

# ci_bump_and_regen.sh
# - Detect changes vs origin/main (or BASE_REF)
# - Determine semver bump from PR labels or SEMVER_BUMP env
# - Bump Chart.yaml versions for affected charts (or all if global inputs changed)
# - Regenerate all examples via make generate-examples
# - Commit changes with bot identity
# - DRY_RUN=true prints actions without modifying the repo

BOT_NAME=${BOT_NAME:-"github-actions[bot]"}
BOT_EMAIL=${BOT_EMAIL:-"github-actions[bot]@users.noreply.github.com"}
DRY_RUN=${DRY_RUN:-"false"}
BASE_REF=${BASE_REF:-"origin/main"}

# Default to lowercase labels but accept overrides and legacy values
SEMVER_LABEL_MAJOR=${SEMVER_LABEL_MAJOR:-"semvertype:major"}
SEMVER_LABEL_MINOR=${SEMVER_LABEL_MINOR:-"semvertype:minor"}
SEMVER_LABEL_PATCH=${SEMVER_LABEL_PATCH:-"semvertype:patch"}

# Optional: space-separated list of PRs in the merge group
PR_NUMBERS=${PR_NUMBERS:-""}

echo "[info] Base ref: ${BASE_REF}"
git fetch --no-tags --prune --depth=0 origin +refs/heads/*:refs/remotes/origin/* >/dev/null 2>&1 || true

changed_files=$(git diff --name-only "${BASE_REF}...HEAD" || true)
echo "[info] Changed files:"
echo "${changed_files}" | sed 's/^/ - /'

# Safety: If the last commit is already a bot autogen commit, we'll amend it
# instead of creating a new commit to guarantee a single final bot commit.
last_author=$(git log -1 --pretty=format:'%an' || echo "")
last_subject=$(git log -1 --pretty=format:'%s' || echo "")
AMEND_BOT_COMMIT="false"
if [[ "${last_author}" == "${BOT_NAME}" && ${last_subject} == ci:*regenerate*examples* ]]; then
  echo "[info] Amending existing bot autogen commit at HEAD: '${last_subject}'."
  AMEND_BOT_COMMIT="true"
fi

regenerate_all=false
affected_charts=()

is_global_input() {
  local f="$1"
  case "$f" in
    Makefile|.github/scripts/*)
      return 0 ;;
  esac
  return 1
}

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if is_global_input "$f"; then
    regenerate_all=true
  fi
  if [[ "$f" == charts/*/* ]]; then
    if [[ "$f" == charts/*/examples/*/rendered/* ]]; then
      continue
    fi
    chart_dir=${f#charts/}
    chart_dir=${chart_dir%%/*}
    [[ -n "$chart_dir" ]] && affected_charts+=("$chart_dir")
  fi
done <<< "${changed_files}"

if [[ ${#affected_charts[@]} -gt 0 ]]; then
  mapfile -t affected_charts < <(printf '%s\n' "${affected_charts[@]}" | sort -u)
fi

if [[ "$regenerate_all" == "true" ]]; then
  echo "[info] Global inputs changed -> full regeneration and bump for all charts."
else
  if [[ ${#affected_charts[@]} -eq 0 ]]; then
    echo "[info] No chart inputs changed. Skipping bump and regeneration."
    exit 0
  fi
fi

# Determine bump type
semver_bump=${SEMVER_BUMP:-""}

label_to_bump() {
  case "$1" in
    "$SEMVER_LABEL_MAJOR"|"SemVerType: Major"|"semvertype:major") echo major ;;
    "$SEMVER_LABEL_MINOR"|"SemVerType: Minor"|"semvertype:minor") echo minor ;;
    "$SEMVER_LABEL_PATCH"|"SemVerType: Patch"|"semvertype:patch") echo patch ;;
  esac
}

max_bump() {
  local current="$1" candidate="$2"
  [[ "$current" == "major" || -z "$candidate" ]] && { echo "$current"; return; }
  [[ "$candidate" == "major" ]] && { echo major; return; }
  if [[ "$current" == "minor" ]]; then echo minor; else echo "$candidate"; fi
}

declare -A chart_bump

# Build per-chart max bump from PR labels when available
if [[ -n "$PR_NUMBERS" && -n "${GITHUB_REPOSITORY:-}" && -n "${GITHUB_TOKEN:-}" && $(command -v jq >/dev/null 2>&1; echo $?) -eq 0 ]]; then
  for pr in $PR_NUMBERS; do
    pr_api="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pr}"
    labels=$(curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "$pr_api" | jq -r '.labels[].name') || true
    pr_chart=""; pr_bump=""
    while IFS= read -r lbl; do
      # chart label
      if [[ "$lbl" == chart:* ]]; then
        pr_chart=${lbl#chart:}
      fi
      # bump label
      b=$(label_to_bump "$lbl" || true)
      if [[ -n "$b" ]]; then
        pr_bump=$b
      fi
    done <<< "$labels"
    if [[ -n "$pr_chart" && -n "$pr_bump" ]]; then
      current=${chart_bump[$pr_chart]:-}
      if [[ -z "$current" ]]; then
        chart_bump[$pr_chart]="$pr_bump"
      else
        chart_bump[$pr_chart]=$(max_bump "$current" "$pr_bump")
      fi
    fi
  done
fi

# Fallback: if no per-chart mapping, use global bump (env or computed) for affected charts
if [[ ${#chart_bump[@]} -eq 0 ]]; then
  if [[ -z "$semver_bump" && -n "$PR_NUMBERS" ]]; then
    echo "[error] No per-PR labels found; set SEMVER_BUMP=major|minor|patch or ensure PRs are labeled." >&2
    exit 2
  fi
  for cdn in "${affected_charts[@]}"; do
    chart_bump[$cdn]="$semver_bump"
  done
fi

# Only bump charts that have input changes in this train (affected_charts). If regenerate_all, restrict to charts that appear in chart_bump.
charts_to_bump_sorted=()
if [[ "$regenerate_all" == "true" ]]; then
  for c in "${!chart_bump[@]}"; do
    charts_to_bump_sorted+=("$c")
  done
else
  for c in "${affected_charts[@]}"; do
    [[ -n "${chart_bump[$c]:-}" ]] && charts_to_bump_sorted+=("$c")
  done
fi

if [[ ${#charts_to_bump_sorted[@]} -eq 0 ]]; then
  echo "[info] No charts require version bump in this train."
else
  mapfile -t charts_to_bump_sorted < <(printf '%s\n' "${charts_to_bump_sorted[@]}" | sort -u)
  echo "[info] Charts to bump (max once each): ${charts_to_bump_sorted[*]}"
  for cdn in "${charts_to_bump_sorted[@]}"; do
    chart_yaml="charts/${cdn}/Chart.yaml"
    [[ -f "$chart_yaml" ]] || continue
    bump_kind="${chart_bump[$cdn]}"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "DRY_RUN: .github/scripts/bump_chart_version.sh '$chart_yaml' '$bump_kind'"
    else
      bash .github/scripts/bump_chart_version.sh "$chart_yaml" "$bump_kind" >/dev/null
    fi
  done
fi

echo "[info] Running make generate-examples (all charts)"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY_RUN: make generate-examples"
else
  make generate-examples
fi

if git diff --quiet && git diff --cached --quiet; then
  echo "[info] Nothing to commit after bump and regen."
  exit 0
fi

subject="ci: bump Chart.yaml and regenerate examples"
if [[ ${#charts_to_bump_sorted[@]} -gt 0 ]]; then
  subject+=" for [${charts_to_bump_sorted[*]}]"
fi
[[ -n "$PR_NUMBERS" ]] && subject+=" (PRs ${PR_NUMBERS})"

echo "[info] Committing: $subject"
if [[ "$DRY_RUN" == "true" ]]; then
  if [[ "$AMEND_BOT_COMMIT" == "true" ]]; then
    echo "DRY_RUN: git add -A && git -c user.name='$BOT_NAME' -c user.email='$BOT_EMAIL' commit --amend -m '$subject'"
  else
    echo "DRY_RUN: git add -A && git -c user.name='$BOT_NAME' -c user.email='$BOT_EMAIL' commit -m '$subject'"
  fi
  exit 0
fi

git config user.name "$BOT_NAME"
git config user.email "$BOT_EMAIL"
git add -A
if [[ "$AMEND_BOT_COMMIT" == "true" ]]; then
  git commit --amend -m "$subject"
else
  git commit -m "$subject"
fi

echo "[info] Commit created. Push should be performed by the workflow."

#!/usr/bin/env bash
set -euo pipefail

# ci_bump_and_regen.sh
# - Detect changes vs origin/main (or BASE_REF)
# - Determine semver bump from PR labels or SEMVER_BUMP env
# - Bump Chart.yaml versions for affected charts (or all if global inputs changed)
# - Regenerate all examples via make generate-examples
# - Commit changes with bot identity
# - DRY_RUN=true prints actions without modifying the repo

BOT_NAME=${BOT_NAME:-"github-actions[bot]"}
BOT_EMAIL=${BOT_EMAIL:-"github-actions[bot]@users.noreply.github.com"}
DRY_RUN=${DRY_RUN:-"false"}
BASE_REF=${BASE_REF:-"origin/main"}

# Default to lowercase labels but accept overrides and legacy values
SEMVER_LABEL_MAJOR=${SEMVER_LABEL_MAJOR:-"semvertype:major"}
SEMVER_LABEL_MINOR=${SEMVER_LABEL_MINOR:-"semvertype:minor"}
SEMVER_LABEL_PATCH=${SEMVER_LABEL_PATCH:-"semvertype:patch"}

# Optional: space-separated list of PRs in the merge group
PR_NUMBERS=${PR_NUMBERS:-""}

echo "[info] Base ref: ${BASE_REF}"
git fetch --no-tags --prune --depth=0 origin +refs/heads/*:refs/remotes/origin/* >/dev/null 2>&1 || true

changed_files=$(git diff --name-only "${BASE_REF}...HEAD" || true)
echo "[info] Changed files:"
echo "${changed_files}" | sed 's/^/ - /'

# Safety: If the last commit already is an autogen bot commit and there are
# no non-bot commits after it, skip to avoid loops on train branches.
last_author=$(git log -1 --pretty=format:'%an' || echo "")
last_subject=$(git log -1 --pretty=format:'%s' || echo "")
if [[ "${last_author}" == "${BOT_NAME}" && ${last_subject} == ci:*regenerate*examples* ]]; then
  echo "[info] Last commit is already an autogen commit by ${BOT_NAME}: '${last_subject}'. Skipping to avoid loops."
  exit 0
fi

regenerate_all=false
affected_charts=()

is_global_input() {
  local f="$1"
  case "$f" in
    Makefile|.github/scripts/*)
      return 0 ;;
  esac
  return 1
}

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if is_global_input "$f"; then
    regenerate_all=true
  fi
  if [[ "$f" == charts/*/* ]]; then
    if [[ "$f" == charts/*/examples/*/rendered/* ]]; then
      continue
    fi
    chart_dir=${f#charts/}
    chart_dir=${chart_dir%%/*}
    [[ -n "$chart_dir" ]] && affected_charts+=("$chart_dir")
  fi
done <<< "${changed_files}"

if [[ ${#affected_charts[@]} -gt 0 ]]; then
  mapfile -t affected_charts < <(printf '%s\n' "${affected_charts[@]}" | sort -u)
fi

if [[ "$regenerate_all" == "true" ]]; then
  echo "[info] Global inputs changed -> full regeneration and bump for all charts."
else
  if [[ ${#affected_charts[@]} -eq 0 ]]; then
    echo "[info] No chart inputs changed. Skipping bump and regeneration."
    exit 0
  fi
fi

# Determine bump type
semver_bump=${SEMVER_BUMP:-""}

label_to_bump() {
  case "$1" in
    "$SEMVER_LABEL_MAJOR"|"SemVerType: Major"|"semvertype:major") echo major ;;
    "$SEMVER_LABEL_MINOR"|"SemVerType: Minor"|"semvertype:minor") echo minor ;;
    "$SEMVER_LABEL_PATCH"|"SemVerType: Patch"|"semvertype:patch") echo patch ;;
  esac
}

max_bump() {
  local current="$1" candidate="$2"
  [[ "$current" == "major" || -z "$candidate" ]] && { echo "$current"; return; }
  [[ "$candidate" == "major" ]] && { echo major; return; }
  if [[ "$current" == "minor" ]]; then echo minor; else echo "$candidate"; fi
}

if [[ -z "$semver_bump" && -n "$PR_NUMBERS" ]]; then
  if [[ -z "${GITHUB_REPOSITORY:-}" || -z "${GITHUB_TOKEN:-}" ]]; then
    echo "[warn] Missing GITHUB_REPOSITORY/GITHUB_TOKEN; cannot fetch labels."
  else
    if command -v jq >/dev/null 2>&1; then
      tmp_bump=""
      for pr in $PR_NUMBERS; do
        pr_api="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${pr}"
        labels=$(curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" "$pr_api" | jq -r '.labels[].name') || true
        while IFS= read -r lbl; do
          b=$(label_to_bump "$lbl" || true)
          [[ -n "$b" ]] && tmp_bump=$(max_bump "${tmp_bump:-}" "$b")
        done <<< "$labels"
      done
      semver_bump=${tmp_bump:-""}
    else
      echo "[warn] jq not available; cannot compute bump from labels."
    fi
  fi
fi

if [[ -z "$semver_bump" ]]; then
  echo "[error] Missing SemVer label. Expected one of: '$SEMVER_LABEL_MAJOR', '$SEMVER_LABEL_MINOR', '$SEMVER_LABEL_PATCH'." >&2
  echo "[hint] Set SEMVER_BUMP=major|minor|patch or ensure PRs have labels." >&2
  exit 2
fi

echo "[info] SemVer bump: $semver_bump"

# Decide which charts to bump
charts_to_bump=()
if [[ "$regenerate_all" == "true" ]]; then
  while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    charts_to_bump+=("$dir")
  done < <(find charts -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort)
else
  charts_to_bump=("${affected_charts[@]}")
fi

echo "[info] Charts to bump: ${charts_to_bump[*]}"

for cdn in "${charts_to_bump[@]}"; do
  chart_yaml="charts/${cdn}/Chart.yaml"
  [[ -f "$chart_yaml" ]] || continue
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "DRY_RUN: .github/scripts/bump_chart_version.sh '$chart_yaml' '$semver_bump'"
  else
    bash .github/scripts/bump_chart_version.sh "$chart_yaml" "$semver_bump" >/dev/null
  fi
done

echo "[info] Running make generate-examples (all charts)"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY_RUN: make generate-examples"
else
  make generate-examples
fi

if git diff --quiet && git diff --cached --quiet; then
  echo "[info] Nothing to commit after bump and regen."
  exit 0
fi

subject="ci: bump Chart.yaml (${semver_bump}) and regenerate examples"
if [[ -n "$PR_NUMBERS" ]]; then
  subject+=" (PRs ${PR_NUMBERS})"
fi

echo "[info] Committing: $subject"
if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY_RUN: git add -A && git -c user.name='$BOT_NAME' -c user.email='$BOT_EMAIL' commit -m '$subject'"
  exit 0
fi

git config user.name "$BOT_NAME"
git config user.email "$BOT_EMAIL"
git add -A
git commit -m "$subject"

echo "[info] Commit created. Push should be performed by the workflow."


