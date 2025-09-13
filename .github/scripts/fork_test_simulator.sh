#!/usr/bin/env bash
set -euo pipefail

# TODO: remove after testing is completed after access to secret filled enviornment is aquired
# fork_demo.sh
# Quick setup and demo of the Mergify train flow on a forked repository.
#
# Subcommands:
#   setup-labels             Create required labels (chart:* and semvertype:*)
#   demo-pr [chart] [bump]   Create a demo PR for a chart with a semver bump (patch|minor|major)
#   reset [branch]           Delete the demo branch and close the PR if open
#
# Requirements:
#   - gh CLI authenticated (gh auth login)
#   - git, make, helm installed

REPO=${REPO:-"$(git config --get remote.origin.url | sed -E 's#.*github.com[:/](.*)\.git#\1#')"}
BASE_BRANCH=${BASE_BRANCH:-"main"}

CHARTS=(
  opentelemetry-collector
  opentelemetry-operator
  opentelemetry-demo
  opentelemetry-ebpf
  opentelemetry-kube-stack
  opentelemetry-target-allocator
)

create_labels() {
  echo "Creating semvertype labels..."
  for l in semvertype:patch semvertype:minor semvertype:major; do
    gh label create "$l" --color FFD700 --description "semver bump level" --repo "$REPO" 2>/dev/null || echo "label '$l' exists"
  done
  echo "Creating chart labels..."
  for c in "${CHARTS[@]}"; do
    lab="chart:${c}"
    gh label create "$lab" --color 87CEEB --description "chart target" --repo "$REPO" 2>/dev/null || echo "label '$lab' exists"
  done
}

ensure_branch() {
  local branch="$1"
  git fetch origin "$BASE_BRANCH" --depth=0
  git checkout -B "$branch" "origin/${BASE_BRANCH}"
}

change_chart() {
  local chart="$1"
  # Trivial change to a values file to avoid committing rendered outputs
  local values_file="charts/${chart}/values.yaml"
  if [[ -f "$values_file" ]]; then
    echo "# demo change $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$values_file"
  else
    local chy="charts/${chart}/Chart.yaml"
    [[ -f "$chy" ]] && echo "# demo change" >> "$chy"
  fi
}

create_pr() {
  local branch="$1" chart="$2" bump="$3"
  local title="demo: ${chart} ${bump} change"
  local body="Demo PR to exercise Mergify train: bump then regenerate on train."
  gh pr create --title "$title" --body "$body" --base "$BASE_BRANCH" --head "$branch" --repo "$REPO" \
    --label "chart:${chart}" --label "semvertype:${bump}"
}

approve_pr() {
  local pr_number="$1"
  gh pr review "$pr_number" --approve --repo "$REPO"
}

find_open_pr_for_branch() {
  local branch="$1"
  gh pr list --repo "$REPO" --json number,headRefName,state --jq \
    ".[] | select(.headRefName==\"${branch}\" and .state==\"OPEN\").number" | head -n1
}

cmd_setup_labels() {
  create_labels
  echo "Labels are ready in $REPO"
}

cmd_demo_pr() {
  local chart="${1:-opentelemetry-collector}"
  local bump="${2:-patch}"
  local branch="demo/${chart}-${bump}-$(date +%s)"

  if [[ ! " ${CHARTS[*]} " =~ " ${chart} " ]]; then
    echo "Unknown chart: ${chart}" >&2
    echo "Available: ${CHARTS[*]}" >&2
    exit 1
  fi

  ensure_branch "$branch"
  change_chart "$chart"
  git add -A
  git commit -m "demo: change ${chart}"
  git push -u origin "$branch"
  create_pr "$branch" "$chart" "$bump"
  local pr
  pr=$(find_open_pr_for_branch "$branch" || true)
  if [[ -n "$pr" ]]; then
    echo "Created PR #$pr"
    approve_pr "$pr" || true
  else
    echo "PR creation might have failed; check the repository."
  fi
}

cmd_reset() {
  local branch="${1:-}"
  if [[ -z "$branch" ]]; then
    echo "usage: $0 reset <branch>" >&2
    exit 64
  fi
  local pr
  pr=$(find_open_pr_for_branch "$branch" || true)
  if [[ -n "$pr" ]]; then
    gh pr close "$pr" --delete-branch --repo "$REPO" || true
  else
    git push origin --delete "$branch" || true
  fi
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    setup-labels) shift; cmd_setup_labels "$@" ;;
    demo-pr) shift; cmd_demo_pr "$@" ;;
    reset) shift; cmd_reset "$@" ;;
    *)
      echo "usage: $0 {setup-labels|demo-pr [chart] [patch|minor|major]|reset <branch>}" >&2
      exit 64
      ;;
  esac
}

main "$@"

#!/usr/bin/env bash
set -euo pipefail

# fork_demo.sh
# Quick setup and demo of the Mergify train flow on a forked repository.
#
# Subcommands:
#   setup-labels         Create required labels (chart:* and semvertype:*)
#   demo-pr [chart] [bump]  Create a demo PR for a chart with a semver bump (patch|minor|major)
#   reset [branch]       Delete the demo branch and close the PR if open
#
# Requirements:
#   - gh CLI authenticated (gh auth login)
#   - git, make, helm installed
#

REPO=${REPO:-"$(git config --get remote.origin.url | sed -E 's#.*github.com[:/](.*)\.git#\1#')"}
OWNER=${OWNER:-"${REPO%%/*}"}
NAME=${NAME:-"${REPO##*/}"}
BASE_BRANCH=${BASE_BRANCH:-"main"}

CHARTS=(
  opentelemetry-collector
  opentelemetry-operator
  opentelemetry-demo
  opentelemetry-ebpf
  opentelemetry-kube-stack
  opentelemetry-target-allocator
)

create_labels() {
  echo "Creating semvertype labels..."
  for l in semvertype:patch semvertype:minor semvertype:major; do
    gh label create "$l" --color FFD700 --description "semver bump level" --repo "$REPO" 2>/dev/null || echo "label '$l' exists"
  done
  echo "Creating chart labels..."
  for c in "${CHARTS[@]}"; do
    lab="chart:${c}"
    gh label create "$lab" --color 87CEEB --description "chart target" --repo "$REPO" 2>/dev/null || echo "label '$lab' exists"
  done
}

ensure_branch() {
  local branch="$1"
  git fetch origin "$BASE_BRANCH" --depth=0
  git checkout -B "$branch" "origin/${BASE_BRANCH}"
}

change_chart() {
  local chart="$1"
  # Introduce a harmless whitespace change in a template to trigger regeneration
  local tmpl="charts/${chart}/templates/service.yaml"
  if [[ -f "$tmpl" ]]; then
    echo "# demo change $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$tmpl"
  else
    # fallback: Chart.yaml description minor whitespace
    local chy="charts/${chart}/Chart.yaml"
    [[ -f "$chy" ]] && echo "# demo change" >> "$chy"
  fi
}

run_generate() {
  make generate-examples
}

create_pr() {
  local branch="$1" chart="$2" bump="$3"
  local title="demo: ${chart} ${bump} change"
  local body="Demo PR to exercise Mergify train: bump then regenerate on train."
  gh pr create --title "$title" --body "$body" --base "$BASE_BRANCH" --head "$branch" --repo "$REPO" \
    --label "chart:${chart}" --label "semvertype:${bump}"
}

approve_pr() {
  local pr_number="$1"
  gh pr review "$pr_number" --approve --repo "$REPO"
}

find_open_pr_for_branch() {
  local branch="$1"
  gh pr list --repo "$REPO" --json number,headRefName,state --jq \
    ".[] | select(.headRefName==\"${branch}\" and .state==\"OPEN\").number" | head -n1
}

cmd_setup_labels() {
  create_labels
  echo "Labels are ready in $REPO"
}

cmd_demo_pr() {
  local chart="${1:-opentelemetry-collector}"
  local bump="${2:-patch}"
  local branch="demo/${chart}-${bump}-$(date +%s)"

  if [[ ! " ${CHARTS[*]} " =~ " ${chart} " ]]; then
    echo "Unknown chart: ${chart}" >&2
    echo "Available: ${CHARTS[*]}" >&2
    exit 1
  fi

  ensure_branch "$branch"
  change_chart "$chart"
  run_generate
  git add -A
  git commit -m "demo: change ${chart} and regenerate examples"
  git push -u origin "$branch"
  create_pr "$branch" "$chart" "$bump"
  local pr
  pr=$(find_open_pr_for_branch "$branch" || true)
  if [[ -n "$pr" ]]; then
    echo "Created PR #$pr"
    approve_pr "$pr" || true
  else
    echo "PR creation might have failed; check the repository."
  fi
}

cmd_reset() {
  local branch="${1:-}"
  if [[ -z "$branch" ]]; then
    echo "usage: $0 reset <branch>" >&2
    exit 64
  fi
  local pr
  pr=$(find_open_pr_for_branch "$branch" || true)
  if [[ -n "$pr" ]]; then
    gh pr close "$pr" --delete-branch --repo "$REPO" || true
  else
    git push origin --delete "$branch" || true
  fi
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    setup-labels) shift; cmd_setup_labels "$@" ;;
    demo-pr) shift; cmd_demo_pr "$@" ;;
    reset) shift; cmd_reset "$@" ;;
    *)
      echo "usage: $0 {setup-labels|demo-pr [chart] [patch|minor|major]|reset <branch>}" >&2
      exit 64
      ;;
  esac
}

main "$@"


