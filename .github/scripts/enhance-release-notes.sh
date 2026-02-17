#!/bin/bash
# Script to enhance release notes with upstream OpenTelemetry project links

set -euo pipefail

# Get the repository from environment or default
REPO="${GITHUB_REPOSITORY:-open-telemetry/opentelemetry-helm-charts}"

# Function to update release notes for a chart
update_release_notes() {
    local chart_name="$1"
    local chart_version="$2"
    local app_version="$3"
    local release_tag="${chart_name}-${chart_version}"

    echo "Updating release notes for ${release_tag}"

    # Generate enhanced release notes
    enhanced_notes=$(.github/scripts/generate-release-notes.sh "$chart_name" "$chart_version" "$app_version" "charts/$chart_name/")

    # Get the current release notes
    current_notes=$(gh release view "$release_tag" --repo "$REPO" --json body --jq '.body' 2>/dev/null || echo "")

    if [[ -z "$current_notes" ]]; then
        echo "ERROR: No existing release notes found for ${release_tag}. This indicates a problem with the chart-releaser process."
        echo "Expected chart-releaser to generate initial release notes, but none were found."
        exit 1
    fi

    # Combine current notes with enhanced notes
    combined_notes="$current_notes

---

$enhanced_notes"

    # Update the release notes
    gh release edit "$release_tag" --repo "$REPO" --notes "$combined_notes"
}

# Main function to enhance release notes for recent releases
enhance_release_notes() {
    # Check each chart for recent releases
    for chart_dir in charts/*/; do
        if [ -f "${chart_dir}Chart.yaml" ]; then
            chart_name=$(basename "$chart_dir")
            chart_version=$(grep '^version:' "${chart_dir}Chart.yaml" | cut -d' ' -f2)
            app_version=$(grep '^appVersion:' "${chart_dir}Chart.yaml" | cut -d' ' -f2)
            release_tag="${chart_name}-${chart_version}"

            # Check if this release was just created (within the last 5 minutes)
            if gh release view "$release_tag" --repo "$REPO" >/dev/null 2>&1; then
                release_date=$(gh release view "$release_tag" --repo "$REPO" --json publishedAt --jq '.publishedAt')
                release_timestamp=$(date -d "$release_date" +%s)
                current_timestamp=$(date +%s)
                time_diff=$((current_timestamp - release_timestamp))

                # If release was created within the last 5 minutes (300 seconds), check if appVersion changed
                if [[ $time_diff -lt 300 ]]; then
                    # Check if appVersion changed compared to the previous chart version
                    previous_chart_version=$(git tag -l "${chart_name}-*" --sort=-version:refname | grep -v "^${release_tag}$" | head -1)

                    if [[ -n "$previous_chart_version" ]]; then
                        # Get the previous appVersion from git
                        previous_app_version=$(git show "${previous_chart_version}:charts/${chart_name}/Chart.yaml" 2>/dev/null | grep '^appVersion:' | cut -d' ' -f2 || echo "")

                        if [[ "$app_version" != "$previous_app_version" && -n "$previous_app_version" ]]; then
                            echo "AppVersion changed from ${previous_app_version} to ${app_version} - enhancing release notes"
                            update_release_notes "$chart_name" "$chart_version" "$app_version"
                        else
                            echo "AppVersion unchanged (${app_version}) - skipping release notes enhancement for ${release_tag}"
                        fi
                    else
                        echo "No previous release found - enhancing release notes for initial release ${release_tag}"
                        update_release_notes "$chart_name" "$chart_version" "$app_version"
                    fi
                fi
            fi
        fi
    done
}

# Execute main function
enhance_release_notes
