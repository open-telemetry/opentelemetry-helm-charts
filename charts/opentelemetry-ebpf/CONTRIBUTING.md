# OpenTelemetry eBPF Chart Contributing Guide

All changes to the chart require a bump to the version in `chart.yaml`. See the [Contributing Guide](https://github.com/liteverge/opentelemetry-helm-charts/blob/main/CONTRIBUTING.md#versioning) for our versioning requirements.

Once the chart version is bumped, the examples must be regenerated.  You can regenerate examples by running `make generate-examples CHARTS=opentelemetry-ebpf`.

## Bumping Default Collector Version

1. Increase the minor version of the chart by one and set the patch version to zero.
2. Update the chart's `appVersion` to match the new collector version.  This version will be used as the image tag by default.
3. Review the corresponding release notes in [Opentelemetry eBPF](https://github.com/open-telemetry/opentelemetry-ebpf/releases).  If any changes affect the helm charts, adjust the helm chart accordingly.
4. Run `make generate-examples CHARTS=opentelemetry-ebpf`.
