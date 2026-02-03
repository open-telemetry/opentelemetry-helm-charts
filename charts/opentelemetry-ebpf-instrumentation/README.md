# OpenTelemetry eBPF Instrumentation Helm Chart

The helm chart installs [OpenTelemetry eBPF Instrumentation](https://github.com/open-telemetry/opentelemetry-ebpf-instrumentation)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-opentelemetry-ebpf, run the following command:

```console
helm install my-opentelemetry-ebpf-instrumentation open-telemetry/opentelemetry-ebpf-instrumentation
```

## Configuration

The [values.yaml](./values.yaml) file contains information about configuration
options for this chart.

### Configuring Dynamic `cluster_name`

The `cluster_name` configuration can be set dynamically from user-provided
values or external resources. Two patterns are supported:

#### Pattern A: Chart-Managed `ConfigMap` (Recommended)

Configure the cluster name directly in the chart values. The chart creates a
`ConfigMap` and automatically restarts pods when the value changes:

```yaml
config:
  create: true
  data:
    cluster_name: "my-production-cluster"
```

This approach will automatically restart OBI pods on any configuration change
and is simplest.

#### Pattern B: External `ConfigMap` with Manual Restart

Use an existing `ConfigMap` managed outside the chart:

1. Create a `ConfigMap` with the cluster name:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: cluster-config
   data:
     cluster_name: "my-production-cluster"
   ```

2. Configure the chart to reference the `cluster_name` key in the `ConfigMap`:

   ```yaml
   envValueFrom:
     OTEL_EBPF_KUBE_CLUSTER_NAME:
       configMapKeyRef:
         name: cluster-config
         key: cluster_name
   ```

This approach has the limitation that OBI pod restarts must be triggered
manually when the `ConfigMap` is updated:

```bash
kubectl rollout restart daemonset \
  -l app.kubernetes.io/name=opentelemetry-ebpf-instrumentation
```

See the next section for automating this process.

##### Dynamic OBI Pod restart

To automatically restart OBI pods when the external `ConfigMap` changes, add a
checksum annotation:

```yaml
podAnnotations:
  checksum/cluster-config: '{{ (.Files.Get "cluster-config.yaml" | sha256sum) }}'
```

This requires bundling the `ConfigMap` definition in the Helm release for
checksum evaluation.

### Pod Annotations with Template Support

The `podAnnotations` values support Helm templating, enabling dynamic values:

```yaml
podAnnotations:
  # Custom static annotation
  custom-annotation: "custom-value"

  # Reference Helm values
  environment: '{{ .Values.environment }}'

  # Reference release info
  release: '{{ .Release.Name }}'

  # Compute checksums for external resources
  checksum/cluster: '{{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}'
```
