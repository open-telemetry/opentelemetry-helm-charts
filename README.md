# Log10x OpenTelemetry Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Release Status](https://github.com/log-10x/opentelemetry-helm-charts/actions/workflows/release.yaml/badge.svg?branch=main)](https://github.com/log-10x/opentelemetry-helm-charts/actions/workflows/release.yaml)

Helm charts for deploying OpenTelemetry Collector with an [10x Edge app](https://doc.log10x.com/apps/edge)

The OpenTelemetry Collector charts are built on top of the official [opentelemetry helm charts](https://github.com/open-telemetry/opentelemetry-helm-charts), and work by deploying a Log10x sidecar alongside the collector for log optimization.

For more details on how the images are created, see the [docker-images repo](https://github.com/log-10x/docker-images).

The supported [10x distributions](https://doc.log10x.com/architecture/flavors/) are JIT Edge and Native Edge. Check out each individual chart values.yaml for full configuration options.

## Usage

[Helm](https://helm.sh) must be installed to use these charts; please refer to the _Helm_ [documentation](https://helm.sh/docs/) to get started.

### OCI Repository (Recommended)

Install directly from the OCI registry:

```shell
# Install opentelemetry-collector
helm install my-collector oci://ghcr.io/log-10x/opentelemetry-helm-charts/opentelemetry-collector

# Install a specific version
helm install my-collector oci://ghcr.io/log-10x/opentelemetry-helm-charts/opentelemetry-collector --version 1.0.6

# Show chart info and available versions
helm show all oci://ghcr.io/log-10x/opentelemetry-helm-charts/opentelemetry-collector
```

No `helm repo add` required - OCI pulls directly from the registry.

### Helm Repository (Alternative)

Add the Helm repository:

```shell
helm repo add log10x-otel https://log-10x.github.io/opentelemetry-helm-charts
helm repo update
helm search repo log10x-otel
```

Then install:

```shell
helm install my-collector log10x-otel/opentelemetry-collector
```

## Charts

- [opentelemetry-collector](./charts/opentelemetry-collector/README.md) - OpenTelemetry Collector with Log10x integration

## Log10x Integration

Enable Log10x by setting `tenx.enabled: true` in your values file:

```yaml
tenx:
  enabled: true
  apiKey: "YOUR-LICENSE-KEY"
  kind: "regulate"  # Options: report, regulate, optimize
  runtimeName: "my-otel-collector"

  # Optional: GitOps configuration
  github:
    config:
      enabled: true
      token: "YOUR-GITHUB-TOKEN"
      repo: "YOUR-ORG/YOUR-CONFIG-REPO"
```

### Log10x Modes

| Mode | Description |
|------|-------------|
| `report` | Analytics-only mode - generates cost and usage metrics without modifying logs |
| `regulate` | Filtering mode - reduces log volume based on configured rules |
| `optimize` | Full optimization - reduces log volume while preserving information |

## Documentation

- [Log10x Documentation](https://doc.log10x.com)
- [Edge Reporter Deployment](https://doc.log10x.com/apps/edge/reporter/deploy/)
- [Edge Regulator Deployment](https://doc.log10x.com/apps/edge/regulator/deploy/)
- [Edge Optimizer Deployment](https://doc.log10x.com/apps/edge/optimizer/deploy/)

## License

This repository is licensed under the [Apache License 2.0](LICENSE).

### Important: Log10x Product License Required

This repository contains deployment tooling for Log10x with OpenTelemetry. While the tooling
itself is open source, **using Log10x requires a commercial license**.

| Component | License |
|-----------|---------|
| This repository (Helm charts) | Apache 2.0 (open source) |
| Log10x engine and runtime | Commercial license required |

**What this means:**

- You can freely use, modify, and distribute these Helm charts
- The Log10x software that these charts deploy requires a paid subscription
- A valid Log10x API key is required to run the deployed software

**Get Started:**

- [Log10x Pricing](https://log10x.com/pricing)
- [Documentation](https://doc.log10x.com)
- [Contact Sales](mailto:sales@log10x.com)
