# Contribution: Enhanced Release Notes with Upstream Links

## Issue Resolution

This contribution addresses [GitHub issue #1594](https://github.com/open-telemetry/opentelemetry-helm-charts/issues/1594): "Release notes - include a link to the relevant project release notes"

## Problem Statement

When bumping versions of workloads like the OpenTelemetry Collector, users had to manually search for the relevant upstream release notes to understand what behavior changes to expect from a Helm package upgrade. This made it difficult to plan upgrades and understand the impact of new versions.

## Solution

The solution adds an automated enhancement to the release process that:

1. **Automatically detects new releases** within 5 minutes of creation
2. **Generates enhanced release notes** with direct links to upstream OpenTelemetry project release notes
3. **Updates existing release notes** with the enhanced content
4. **Provides consistent formatting** across all chart releases

## Implementation Details

### Files Added/Modified

1. **`.github/workflows/release.yaml`**
   - Added a new step "Enhance release notes with upstream links"
   - Integrated the enhancement process into the existing release workflow
   - Uses GitHub CLI to update release notes after creation

2. **`.github/scripts/generate-release-notes.sh`** (New)
   - Bash script that generates enhanced release notes
   - Supports different chart types with specific upstream project links
   - Provides consistent formatting and installation instructions

3. **`.github/cr.yaml`** (New)
   - Configuration file for chart-releaser
   - Enables automatic release notes generation

4. **`ENHANCED_RELEASE_NOTES.md`** (New)
   - Documentation explaining the enhancement
   - Examples of enhanced release notes
   - Maintenance information

### Technical Approach

The solution uses a post-processing approach:

1. **Chart-releaser runs normally** and creates releases with default notes
2. **Enhancement step detects new releases** by checking creation timestamps
3. **Custom script generates enhanced notes** with upstream links
4. **GitHub CLI updates the release** with combined original and enhanced notes

### Chart-Specific Logic

The script intelligently determines which upstream projects to link to based on the chart name:

- **opentelemetry-collector**: Links to Collector and Collector Contrib
- **opentelemetry-operator**: Links to Operator project
- **opentelemetry-demo**: Links to Demo project
- **opentelemetry-target-allocator**: Links to Operator project (TA is part of Operator)
- **Other charts**: Generic upstream message

## Example Output

For an `opentelemetry-collector` release, the enhanced notes include:

```markdown
## Upstream Release Notes

For detailed information about the changes in this release, please refer to the upstream OpenTelemetry project release notes:

- [OpenTelemetry Collector v0.128.0](https://github.com/open-telemetry/opentelemetry-collector/releases/tag/v0.128.0)
- [OpenTelemetry Collector Contrib v0.128.0](https://github.com/open-telemetry/opentelemetry-collector-contrib/releases/tag/v0.128.0)
```

## Benefits

- **Improved User Experience**: Users can directly access relevant upstream release notes
- **Better Upgrade Planning**: Clear understanding of what changes to expect
- **Automated Process**: No manual intervention required
- **Consistent Format**: All releases follow the same enhanced format
- **Backward Compatible**: Existing release process unchanged

## Testing

The enhancement can be tested by:

1. Running the script manually: `bash .github/scripts/generate-release-notes.sh opentelemetry-collector 0.127.1 0.128.0 charts/opentelemetry-collector/`
2. Checking the workflow runs after the changes are merged
3. Verifying that new releases include the enhanced notes

## Maintenance

The solution is fully automated and self-maintaining. The script automatically:

- Detects chart types
- Generates appropriate upstream links
- Handles version mapping
- Provides consistent formatting

No manual maintenance is required once deployed.
