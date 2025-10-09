#!/bin/bash
# Script to generate release notes with links to upstream OpenTelemetry releases

set -euo pipefail

# Function to get OpenTelemetry Collector release notes URL
get_otel_collector_release_url() {
    local version="$1"
    echo "https://github.com/open-telemetry/opentelemetry-collector/releases/tag/v${version}"
}

# Function to get OpenTelemetry Collector Contrib release notes URL
get_otel_collector_contrib_release_url() {
    local version="$1"
    echo "https://github.com/open-telemetry/opentelemetry-collector-contrib/releases/tag/v${version}"
}

# Function to get OpenTelemetry Operator release notes URL
get_otel_operator_release_url() {
    local version="$1"
    echo "https://github.com/open-telemetry/opentelemetry-operator/releases/tag/v${version}"
}

# Function to get OpenTelemetry Demo release notes URL
get_otel_demo_release_url() {
    local version="$1"
    echo "https://github.com/open-telemetry/opentelemetry-demo/releases/tag/v${version}"
}

# Function to generate release notes for a specific chart
generate_release_notes() {
    local chart_name="$1"
    local chart_version="$2"
    local app_version="$3"
    local chart_path="$4"

    echo "# ${chart_name} ${chart_version}"
    echo ""
    echo "## What's Changed"
    echo ""
    echo "This release updates the ${chart_name} to version ${app_version}."
    echo ""

    # Add links to release notes
    echo "## OpenTelemetry Release Notes"
    echo ""
    case "$chart_name" in
        "opentelemetry-collector")
            echo "- [OpenTelemetry Collector v${app_version}]($(get_otel_collector_release_url "$app_version"))"
            echo "- [OpenTelemetry Collector Contrib v${app_version}]($(get_otel_collector_contrib_release_url "$app_version"))"
            ;;
        "opentelemetry-operator")
            echo "- [OpenTelemetry Operator v${app_version}]($(get_otel_operator_release_url "$app_version"))"
            ;;
        "opentelemetry-demo")
            echo "- [OpenTelemetry Demo v${app_version}]($(get_otel_demo_release_url "$app_version"))"
            ;;
        "opentelemetry-target-allocator")
            echo "- [OpenTelemetry Operator v${app_version}]($(get_otel_operator_release_url "$app_version")) (Target Allocator is part of the Operator project)"
            ;;
        *)
            echo "See upstream OpenTelemetry project releases for details."
            ;;
    esac
    echo ""

    echo "## Chart Information"
    echo ""
    echo "- **Chart Version**: ${chart_version}"
    echo "- **App Version**: ${app_version}"
    echo "- **Chart Path**: ${chart_path}"
    echo ""
    echo "## Installation"
    echo ""
    echo "\`\`\`bash"
    echo "helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts"
    echo "helm repo update"
    echo "helm install my-${chart_name} open-telemetry/${chart_name} --version ${chart_version}"
    echo "\`\`\`"
}

# Main execution
if [ $# -ne 4 ]; then
    echo "Usage: $0 <chart_name> <chart_version> <app_version> <chart_path>"
    exit 1
fi

generate_release_notes "$1" "$2" "$3" "$4"
