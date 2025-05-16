# OpenTelemetry Target Allocator Helm Chart

The helm chart installs [OpenTelemetry Target Allocator](https://github.com/open-telemetry/opentelemetry-operator/tree/main/cmd/otel-allocator)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-target-allocator, run the following command:

```console
helm install my-target-allocator open-telemetry/opentelemetry-target-allocator
```

## Upgrading

See [UPGRADING.md](UPGRADING.md).

## Configuration

### Default configuration

By default this chart will deploy a Target Allocator to scan all namespaces for potential targets, finding all PodMonitor and ServiceMonitor custom resources compatible with the Prometheus Operator.

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.

For more examples see [Examples](examples).
