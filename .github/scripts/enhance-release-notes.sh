#!/bin/bash
# Script to enhance release notes with upstream OpenTelemetry project links

set -euo pipefail

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
    current_notes=$(gh release view "$release_tag" --json body --jq '.body' 2>/dev/null || echo "")

    if [[ -n "$current_notes" ]]; then
        # Combine current notes with enhanced notes
        combined_notes="$current_notes

---

$enhanced_notes"
    else
        combined_notes="$enhanced_notes"
    fi

    # Update the release notes
    gh release edit "$release_tag" --notes "$combined_notes"
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
            if gh release view "$release_tag" >/dev/null 2>&1; then
                release_date=$(gh release view "$release_tag" --json publishedAt --jq '.publishedAt')
                release_timestamp=$(date -d "$release_date" +%s)
                current_timestamp=$(date +%s)
                time_diff=$((current_timestamp - release_timestamp))

                # If release was created within the last 5 minutes (300 seconds), update it
                if [[ $time_diff -lt 300 ]]; then
                    update_release_notes "$chart_name" "$chart_version" "$app_version"
                fi
            fi
        fi
    done
}

# Execute main function
enhance_release_notes
