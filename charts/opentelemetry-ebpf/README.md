# OpenTelemetry Collector eBPF Helm Chart

The helm chart installs [OpenTelemetry eBPF](https://github.com/open-telemetry/opentelemetry-ebpf)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

## Installing the Chart

Add Liteverge OpenTelemetry Helm repository:

```console
helm repo add liteverge-opentelemetry https://liteverge.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-opentelemetry-ebpf, run the following command:

```console
helm install my-opentelemetry-ebpf liteverge-opentelemetry/opentelemetry-ebpf
```

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.

For more examples see [Examples](examples).