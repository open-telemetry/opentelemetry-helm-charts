# Enhanced Release Notes for OpenTelemetry Helm Charts

This enhancement addresses [GitHub issue #1594](https://github.com/open-telemetry/opentelemetry-helm-charts/issues/1594) by adding links to relevant upstream OpenTelemetry project release notes when bumping chart versions.

## Overview

When a new Helm chart version is released, the release notes now include:

1. **Upstream Release Notes Links**: Direct links to the relevant OpenTelemetry project release notes
2. **Chart Information**: Clear information about chart version, app version, and chart path
3. **Installation Instructions**: Ready-to-use installation commands

## How It Works

The enhancement works by:

1. **Automated Detection**: The GitHub Actions workflow detects newly created releases within 5 minutes of their creation
2. **Enhanced Notes Generation**: A custom script generates enhanced release notes with upstream links
3. **Automatic Updates**: The workflow updates the release notes with the enhanced content

## Supported Charts

The enhancement supports the following chart types with specific upstream project links:

- **opentelemetry-collector**: Links to OpenTelemetry Collector and Collector Contrib releases
- **opentelemetry-operator**: Links to OpenTelemetry Operator releases
- **opentelemetry-demo**: Links to OpenTelemetry Demo releases
- **opentelemetry-target-allocator**: Links to OpenTelemetry Operator releases (Target Allocator is part of the Operator project)
- **Other charts**: Generic upstream release notes message

## Example Enhanced Release Notes

Here's an example of what the enhanced release notes look like for the opentelemetry-collector chart:

```markdown
# opentelemetry-collector 0.127.1

## What's Changed

This release updates the opentelemetry-collector to version 0.128.0.

## Upstream Release Notes

For detailed information about the changes in this release, please refer to the upstream OpenTelemetry project release notes:

- [OpenTelemetry Collector v0.128.0](https://github.com/open-telemetry/opentelemetry-collector/releases/tag/v0.128.0)
- [OpenTelemetry Collector Contrib v0.128.0](https://github.com/open-telemetry/opentelemetry-collector-contrib/releases/tag/v0.128.0)

## Chart Information

- **Chart Version**: 0.127.1
- **App Version**: 0.128.0
- **Chart Path**: charts/opentelemetry-collector/

## Installation

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm install my-opentelemetry-collector open-telemetry/opentelemetry-collector --version 0.127.1
```

## Files Modified

1. **`.github/workflows/release.yaml`**: Updated to include the enhanced release notes generation step
2. **`.github/scripts/generate-release-notes.sh`**: New script to generate enhanced release notes
3. **`.github/cr.yaml`**: Configuration file for chart-releaser with enhanced options

## Benefits

- **Easier Upgrade Planning**: Users can quickly access relevant upstream release notes to understand what changes to expect
- **Better Documentation**: Clear information about chart and app versions
- **Improved User Experience**: Direct links eliminate the need for users to search for release notes manually
- **Consistent Format**: All enhanced release notes follow the same format

## Maintenance

The enhancement is fully automated and requires no manual maintenance. The script automatically detects the chart type and generates appropriate upstream links based on the chart name and app version.
