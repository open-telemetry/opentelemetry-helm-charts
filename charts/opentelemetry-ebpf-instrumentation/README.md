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

### Centralizing Kubernetes metadata with `k8s-cache`

By default each OBI Pod opens its own `list`/`watch` connections to the
Kubernetes API server to read Pod, Node, and Service metadata for the entire
cluster (needed to enrich destination/peer attributes on traces, flows and
metrics). On large clusters, or when many OBI replicas run side by side
(`DaemonSet`, large `Deployment`, sidecars), this fan-out can put significant
load on the API server.

`k8s-cache` is an optional companion `Deployment` shipped with OBI. It runs
the Kubernetes informers once on behalf of every OBI Pod and streams the
metadata back over gRPC, so OBI Pods no longer hit the API server for
informer traffic.

> **Note:** Even when `k8s-cache` is enabled, OBI Pods still need their own
> `ServiceAccount` and may perform limited direct Kubernetes API lookups for
> node and cluster metadata. The cache eliminates the per-Pod informer
> watch traffic, not all API access.

The cache is disabled by default. To enable it, set `k8sCache.replicas` to a
non-zero value:

```yaml
k8sCache:
  replicas: 1
```

A single replica is usually enough. For high availability or very large
clusters, increase the replica count — OBI Pods load-balance across them
through the cache `Service` and reconnect to a healthy replica on failure.

When `k8sCache.replicas > 0` the chart deploys the cache `Deployment` and
`Service`, and automatically points the OBI `DaemonSet` at it by setting
`OTEL_EBPF_KUBE_META_CACHE_ADDRESS` to `<k8sCache.service.name>:<k8sCache.service.port>`.
See the `k8sCache` block in [values.yaml](./values.yaml) for image, resource,
and metrics settings, and the
[OBI Kubernetes setup guide](https://opentelemetry.io/docs/zero-code/obi/setup/kubernetes/#centralizing-kubernetes-metadata-with-k8s-cache)
for background.

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
