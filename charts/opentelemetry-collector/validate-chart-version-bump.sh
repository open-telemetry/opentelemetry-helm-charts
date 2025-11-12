#!/bin/bash
set -euo pipefail

# Script to validate that chart version bumps align with appVersion changes
# Usage: ./validate-chart-version-bump.sh

BASE_BRANCH="main"
CHART_PATH="charts/opentelemetry-collector"
CHART_FILE="${CHART_PATH}/Chart.yaml"

echo "Validating chart version bump..."

# Check if Chart.yaml exists
if [[ ! -f "${CHART_FILE}" ]]; then
    echo "Error: ${CHART_FILE} not found"
    exit 1
fi

# Get current versions
CURRENT_CHART_VERSION=$(grep '^version:' "${CHART_FILE}" | awk '{print $2}')
CURRENT_APP_VERSION=$(grep '^appVersion:' "${CHART_FILE}" | awk '{print $2}')

echo "Current chart version: ${CURRENT_CHART_VERSION}"
echo "Current appVersion: ${CURRENT_APP_VERSION}"

# Fetch the base branch
git fetch origin "${BASE_BRANCH}" --depth=1 || {
    echo "Error: Failed to fetch ${BASE_BRANCH}"
    exit 1
}

# Get versions from base branch
BASE_CHART_VERSION=$(git show "origin/${BASE_BRANCH}:${CHART_FILE}" 2>/dev/null | grep '^version:' | awk '{print $2}' || echo "")
BASE_APP_VERSION=$(git show "origin/${BASE_BRANCH}:${CHART_FILE}" 2>/dev/null | grep '^appVersion:' | awk '{print $2}' || echo "")

if [[ -z "${BASE_CHART_VERSION}" ]] || [[ -z "${BASE_APP_VERSION}" ]]; then
    echo "Warning: Could not retrieve base versions from ${BASE_BRANCH}. Skipping validation."
    exit 0
fi

echo "Base chart version: ${BASE_CHART_VERSION}"
echo "Base appVersion: ${BASE_APP_VERSION}"

# Function to parse semantic version and return major, minor, patch
parse_version() {
    local version=$1
    version=${version#v}
    IFS='.' read -r major minor patch <<< "${version}"
    patch=${patch%%-*}
    patch=${patch%%+*}
    echo "${major} ${minor} ${patch}"
}

# Parse versions
read -r CURRENT_CHART_MAJOR CURRENT_CHART_MINOR CURRENT_CHART_PATCH <<< "$(parse_version "${CURRENT_CHART_VERSION}")"
read -r BASE_CHART_MAJOR BASE_CHART_MINOR BASE_CHART_PATCH <<< "$(parse_version "${BASE_CHART_VERSION}")"
read -r CURRENT_APP_MAJOR CURRENT_APP_MINOR CURRENT_APP_PATCH <<< "$(parse_version "${CURRENT_APP_VERSION}")"
read -r BASE_APP_MAJOR BASE_APP_MINOR BASE_APP_PATCH <<< "$(parse_version "${BASE_APP_VERSION}")"

# Check if versions changed
CHART_VERSION_CHANGED=false
[[ "${CURRENT_CHART_VERSION}" != "${BASE_CHART_VERSION}" ]] && CHART_VERSION_CHANGED=true

APP_VERSION_CHANGED=false
[[ "${CURRENT_APP_VERSION}" != "${BASE_APP_VERSION}" ]] && APP_VERSION_CHANGED=true

echo ""
echo "Chart version changed: ${CHART_VERSION_CHANGED}"
echo "App version changed: ${APP_VERSION_CHANGED}"
echo ""

# Validation: Chart version bumped without appVersion change
if [[ "${CHART_VERSION_CHANGED}" == "true" ]] && [[ "${APP_VERSION_CHANGED}" == "false" ]]; then
    # Determine chart version bump type
    CHART_BUMP_TYPE=""
    if [[ "${CURRENT_CHART_MAJOR}" -gt "${BASE_CHART_MAJOR}" ]]; then
        CHART_BUMP_TYPE="major"
    elif [[ "${CURRENT_CHART_MINOR}" -gt "${BASE_CHART_MINOR}" ]]; then
        CHART_BUMP_TYPE="minor"
    elif [[ "${CURRENT_CHART_PATCH}" -gt "${BASE_CHART_PATCH}" ]]; then
        CHART_BUMP_TYPE="patch"
    else
        echo "VALIDATION FAILED"
        echo "Chart version appears to have been downgraded or changed incorrectly."
        echo "Base: ${BASE_CHART_VERSION} -> Current: ${CURRENT_CHART_VERSION}"
        exit 1
    fi
    
    # Patch bumps are allowed without appVersion changes
    if [[ "${CHART_BUMP_TYPE}" == "patch" ]]; then
        echo "Chart version patch bump detected without appVersion change."
        echo "This is allowed. Validation passed."
        exit 0
    fi
    
    # Minor or major bumps require appVersion changes
    echo "VALIDATION FAILED"
    echo "Chart version had a ${CHART_BUMP_TYPE} bump but appVersion did not change."
    echo "Minor/major chart version bumps should only occur when appVersion changes."
    exit 1
fi

# No changes detected
if [[ "${CHART_VERSION_CHANGED}" == "false" ]] && [[ "${APP_VERSION_CHANGED}" == "false" ]]; then
    echo "No version changes detected. Validation passed."
    exit 0
fi

# Both versions changed - validate bump type matches
if [[ "${CHART_VERSION_CHANGED}" == "true" ]] && [[ "${APP_VERSION_CHANGED}" == "true" ]]; then
    # Determine appVersion bump type
    APP_BUMP_TYPE=""
    if [[ "${CURRENT_APP_MAJOR}" -gt "${BASE_APP_MAJOR}" ]]; then
        APP_BUMP_TYPE="major"
    elif [[ "${CURRENT_APP_MINOR}" -gt "${BASE_APP_MINOR}" ]]; then
        APP_BUMP_TYPE="minor"
    elif [[ "${CURRENT_APP_PATCH}" -gt "${BASE_APP_PATCH}" ]]; then
        APP_BUMP_TYPE="patch"
    else
        echo "VALIDATION FAILED"
        echo "appVersion appears to have been downgraded or changed incorrectly."
        echo "Base: ${BASE_APP_VERSION} -> Current: ${CURRENT_APP_VERSION}"
        exit 1
    fi
    
    # Determine chart version bump type
    CHART_BUMP_TYPE=""
    if [[ "${CURRENT_CHART_MAJOR}" -gt "${BASE_CHART_MAJOR}" ]]; then
        CHART_BUMP_TYPE="major"
    elif [[ "${CURRENT_CHART_MINOR}" -gt "${BASE_CHART_MINOR}" ]]; then
        CHART_BUMP_TYPE="minor"
    elif [[ "${CURRENT_CHART_PATCH}" -gt "${BASE_CHART_PATCH}" ]]; then
        CHART_BUMP_TYPE="patch"
    else
        echo "VALIDATION FAILED"
        echo "Chart version appears to have been downgraded or changed incorrectly."
        echo "Base: ${BASE_CHART_VERSION} -> Current: ${CURRENT_CHART_VERSION}"
        exit 1
    fi
    
    echo "App version bump type: ${APP_BUMP_TYPE}"
    echo "Chart version bump type: ${CHART_BUMP_TYPE}"
    echo ""
    
    # Validate bump type matches
    if [[ "${APP_BUMP_TYPE}" == "minor" ]] && [[ "${CHART_BUMP_TYPE}" != "minor" ]]; then
        echo "VALIDATION FAILED"
        echo "appVersion has a minor bump (${BASE_APP_VERSION} -> ${CURRENT_APP_VERSION})"
        echo "but chart version has a ${CHART_BUMP_TYPE} bump (${BASE_CHART_VERSION} -> ${CURRENT_CHART_VERSION})"
        echo "Chart version should have a minor bump when appVersion has a minor bump."
        exit 1
    fi
    
    if [[ "${APP_BUMP_TYPE}" == "patch" ]] && [[ "${CHART_BUMP_TYPE}" == "minor" ]]; then
        echo "VALIDATION FAILED"
        echo "appVersion has only a patch bump (${BASE_APP_VERSION} -> ${CURRENT_APP_VERSION})"
        echo "but chart version has a minor bump (${BASE_CHART_VERSION} -> ${CURRENT_CHART_VERSION})"
        echo "Chart version should not have a minor bump when appVersion only has a patch bump."
        exit 1
    fi
    
    echo "Version bump validation passed."
    echo "Both appVersion and chart version were bumped appropriately."
    exit 0
fi

# Only appVersion changed
if [[ "${CHART_VERSION_CHANGED}" == "false" ]] && [[ "${APP_VERSION_CHANGED}" == "true" ]]; then
    echo "VALIDATION FAILED"
    echo "appVersion changed (${BASE_APP_VERSION} -> ${CURRENT_APP_VERSION}) but chart version was not bumped."
    echo "Chart minor version must be bumped when appVersion changes."
    exit 1
fi
