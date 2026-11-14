# OpenTelemetry Collector eBPF Helm Chart

The helm chart installs [OpenTelemetry eBPF](https://github.com/open-telemetry/opentelemetry-ebpf)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- Helm 4.0+

## Add Repository (can be skipped for OCI repository)

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Chart

For HTTPS repository:

```console
helm install opentelemetry-ebpf open-telemetry/opentelemetry-ebpf
```

For OCI repository:

```console
helm install opentelemetry-ebpf oci://ghcr.io/open-telemetry/opentelemetry-helm-charts/opentelemetry-ebpf
```

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.

For more examples see [Examples](examples).