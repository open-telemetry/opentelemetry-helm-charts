#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_FILE="${SCRIPT_DIR}/Chart.yaml"
EXAMPLES_DIR="${SCRIPT_DIR}/examples"


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Extract appVersion from Chart.yaml
get_collector_version() {
    if [[ ! -f "$CHART_FILE" ]]; then
        error "Chart.yaml not found at $CHART_FILE"
        exit 1
    fi
    
    local version
    version=$(grep "^appVersion:" "$CHART_FILE" | sed 's/appVersion: *//')
    if [[ -z "$version" ]]; then
        error "Could not extract appVersion from Chart.yaml"
        exit 1
    fi
    
    echo "$version"
}

# Extract configuration from configmap YAML
extract_config() {
    local configmap_file="$1"
    
    if [[ ! -f "$configmap_file" ]]; then
        warn "ConfigMap file not found: $configmap_file"
        return 1
    fi
    
    # Extract the relay: | content from the ConfigMap
    sed -n '/^  relay: |/,/^  [^ ]/p' "$configmap_file" | sed '1d;$d' | sed 's/^    //'
}

# Download collector binary if not present
ensure_collector_binary() {
    local version="$1"
    local collector_binary="${SCRIPT_DIR}/otelcol-contrib"
    
    if [[ -f "$collector_binary" ]]; then
        log "Using existing collector binary: $collector_binary" >&2
        echo "$collector_binary"
        return
    fi
    
    # Determine OS and architecture
    local os arch
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(uname -m)
    
    # Map architecture names
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) 
            error "Unsupported architecture: $arch" >&2
            exit 1
            ;;
    esac
    
    local download_url="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${version}/otelcol-contrib_${version}_${os}_${arch}.tar.gz"
    local temp_dir
    temp_dir=$(mktemp -d)
    
    log "Downloading OpenTelemetry Collector v${version} for ${os}/${arch}..." >&2
    
    if ! curl -L -s -o "${temp_dir}/otelcol-contrib.tar.gz" "$download_url"; then
        error "Failed to download collector from: $download_url" >&2
        rm -rf "$temp_dir"
        exit 1
    fi
    
    log "Extracting collector binary..." >&2
    if ! tar -xzf "${temp_dir}/otelcol-contrib.tar.gz" -C "$temp_dir"; then
        error "Failed to extract collector binary" >&2
        rm -rf "$temp_dir"
        exit 1
    fi
    
    if ! mv "${temp_dir}/otelcol-contrib" "$collector_binary"; then
        error "Failed to move collector binary" >&2
        rm -rf "$temp_dir"
        exit 1
    fi
    
    chmod +x "$collector_binary"
    rm -rf "$temp_dir"
    
    log "Collector binary downloaded successfully: $collector_binary" >&2
    echo "$collector_binary"
}

# Check if validation errors should be ignored
should_ignore_errors() {
    local error_output="$1"
    
    # List of error patterns to ignore (common in non-k8s environments)
    local ignore_patterns=(
        "cert path /var/run/secrets/kubernetes.io/serviceaccount"
        "could not be read: open /var/run/secrets/kubernetes.io/serviceaccount"
        "authorization credentials file \"/var/run/secrets/kubernetes.io/serviceaccount"
        "directory must exist: stat /var/lib/otelcol"
        "root_path is supported on linux only"
        "invalid root_path: stat /hostfs"
        "envvar \"K8S_NODE_NAME\" is not set"
        "envvar \"MY_POD_IP\" is not set"
        "envvar \"MY_NODE_NAME\" is not set"
        "CORALOGIX_PRIVATE_KEY.*not specified"
        "domain.*not specified, please fix the configuration"
        "private_key.*not specified, please fix the configuration"
        "profiling signal support is at alpha level"
        "gated under the.*profilesSupport.*feature gate"
        "processors.*unknown type.*routing.*for id.*routing" # https://coralogix.atlassian.net/browse/ES-725
        # Custom Coralogix distribution components not present in upstream otelcol-contrib
        "processors.*unknown type.*ecsattributes.*for id.*ecsattributes/container-logs"
        "unknown type.*ecsattributes"
        "receivers.*unknown type.*awsecscontainermetricsd.*for id.*awsecscontainermetricsd"
        "unknown type.*awsecscontainermetricsd"
    )
    
    # Check if the entire error output should be ignored first (for multiline patterns)
    for pattern in "${ignore_patterns[@]}"; do
        if [[ "$error_output" =~ $pattern ]]; then
            return 0  # Entire error matches an ignore pattern
        fi
    done
    
    # Check if all error lines match ignore patterns (for single line patterns)
    local all_ignored=true
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local line_ignored=false
            for pattern in "${ignore_patterns[@]}"; do
                if [[ "$line" =~ $pattern ]]; then
                    line_ignored=true
                    break
                fi
            done
            if [[ "$line_ignored" == "false" ]]; then
                all_ignored=false
                break
            fi
        fi
    done <<< "$error_output"
    
    if [[ "$all_ignored" == "true" ]]; then
        return 0  # All errors should be ignored
    else
        return 1  # Some errors are real
    fi
}

# Validate configuration using collector
validate_config() {
    local collector_binary="$1"
    local config_content="$2"
    local example_name="$3"
    
    # Create temporary config file
    local temp_config
    temp_config=$(mktemp)
    echo "$config_content" > "$temp_config"
    
    log "Validating configuration for: $example_name"
    
    # Run validation using collector binary
    local validation_output
    validation_output=$("$collector_binary" validate --config="$temp_config" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log "✓ Configuration valid for: $example_name"
        rm "$temp_config"
        return 0
    else
        # Check if errors should be ignored
        if should_ignore_errors "$validation_output"; then
            log "✓ Configuration valid for: $example_name (ignoring expected k8s environment errors)"
            rm "$temp_config"
            return 0
        else
            error "✗ Configuration invalid for: $example_name"
            # Show the validation error (but limit output)
            echo "Validation errors:"
            echo "$validation_output" | head -10 | sed 's/^/  /'
            rm "$temp_config"
            return 1
        fi
    fi
}

# Main function
main() {
    log "Starting OpenTelemetry Collector configuration validation"
    
    # Check if curl and tar are available
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v tar &> /dev/null; then
        error "tar is required but not installed"
        exit 1
    fi
    
    # Get collector version
    local version
    version=$(get_collector_version)
    log "Found collector version: $version"
    
    # Ensure collector binary is available
    local collector_binary
    collector_binary=$(ensure_collector_binary "$version")
    
    # Initialize counters
    local total=0
    local valid=0
    local invalid=0
    local skipped=0
    
    # Iterate through examples
    if [[ ! -d "$EXAMPLES_DIR" ]]; then
        error "Examples directory not found: $EXAMPLES_DIR"
        exit 1
    fi
    
    log "Scanning examples directory: $EXAMPLES_DIR"
    echo ""
    
    for example_dir in "$EXAMPLES_DIR"/*; do
        if [[ ! -d "$example_dir" ]]; then
            continue
        fi
        
        example_name=$(basename "$example_dir")
        configmap_file="$example_dir/rendered/configmap-agent.yaml"
        
        # Skip if no agent configmap exists
        if [[ ! -f "$configmap_file" ]]; then
            # Also check for configmap.yaml (for deployment examples)
            configmap_file="$example_dir/rendered/configmap.yaml"
            if [[ ! -f "$configmap_file" ]]; then
                warn "No configmap found for example: $example_name (skipping)"
                skipped=$((skipped + 1))
                continue
            fi
        fi
        
        total=$((total + 1))
        
        # Extract configuration
        config_content=$(extract_config "$configmap_file")
        if [[ -z "$config_content" ]]; then
            warn "Could not extract configuration from: $configmap_file (skipping)"
            skipped=$((skipped + 1))
            total=$((total - 1))
            continue
        fi
        
        # Validate configuration
        if validate_config "$collector_binary" "$config_content" "$example_name"; then
            valid=$((valid + 1))
        else
            invalid=$((invalid + 1))
        fi
        
        echo ""
    done
    
    # Summary
    echo "============================================"
    log "Validation Summary:"
    log "Total examples processed: $total"
    log "Valid configurations: $valid"
    log "Invalid configurations: $invalid"
    log "Skipped examples: $skipped"
    echo ""
    
    if [[ $invalid -gt 0 ]]; then
        error "Found $invalid invalid configuration(s)!"
        exit 1
    else
        log "All $valid configurations are valid! ✓"
        exit 0
    fi
}

# Run main function
main "$@"