# Upgrade guidelines

## 0.23.x to 0.24.x

The Kubernetes component ServiceMonitors (kube-apiserver, kube-controller-manager, kube-scheduler, kube-etcd, kube-proxy, coredns, and kube-dns) no longer reference service account bearer token or certificate authority files on the Collector's filesystem. This fixes an issue where they would get dropped by Target Allocators that have `spec.prometheusCR.denyFSAccessThroughSMs` set `true`. For authenticated endpoints, the bearer token now comes from a Secret, and the CA comes from the `kube-root-ca.crt` ConfigMap. This change is based on [kube-prometheus-stack prometheus-community/helm-charts#7238](https://github.com/prometheus-community/helm-charts/pull/7238).

The chart creates a dedicated ServiceAccount and a long-lived `kubernetes.io/service-account-token` Secret for authenticated Kubernetes component ServiceMonitors to reference when `kubernetesServiceMonitors.enabled` and `kubernetesServiceMonitors.authorization.create` are both `true`. The ServiceAccount is bound to RBAC that limits it to `GET` requests against the `/metrics` non-resource URL. The generated names can be overridden with `kubernetesServiceMonitors.authorization.serviceAccountName` and `kubernetesServiceMonitors.authorization.secretName`.

An authorization Secret must be in the same namespace as its ServiceMonitor. Normally that is the chart's release namespace. When `kubernetesServiceMonitors.ignoreNamespaceSelectors` is `true`, the chart creates ServiceAccounts and token Secrets only in `default` and `kube-system`, where the Kubernetes component ServiceMonitors are placed.

For collectors with Prometheus CR discovery enabled, the chart defaults `targetAllocator.prometheusCR.secretNamespaces` to these same namespaces so the Target Allocator watches the authorization Secrets for changes. An explicitly configured `secretNamespaces` value is preserved.

By default, the kube-apiserver, kube-controller-manager, and kube-scheduler ServiceMonitors reference this credential. CoreDNS, kube-dns, kube-etcd, and kube-proxy do not configure authorization by default because their default metrics endpoints do not use bearer-token authentication. Their `serviceMonitor.authorization` settings remain configurable for clusters that secure these endpoints separately.

To manage the credential yourself, set `kubernetesServiceMonitors.authorization.create: false` and point each authenticated component's `serviceMonitor.authorization` at an existing Secret. Set `authorization: null` instead for an endpoint that does not require authentication. Chart rendering fails if a ServiceMonitor still references the chart-generated token Secret while its creation is disabled.

The following settings have been removed or replaced. The `authorization` and `tlsConfig` objects are rendered in the Prometheus Operator [`SafeAuthorization`](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.SafeAuthorization) and [`SafeTLSConfig`](https://prometheus-operator.dev/docs/api-reference/api/#monitoring.coreos.com/v1.SafeTLSConfig) formats.

| Previous setting | Replacement |
| --- | --- |
| Hard-coded `bearerTokenFile` on every exporter ServiceMonitor | `<component>.serviceMonitor.authorization` |
| Hard-coded kube-apiserver `tlsConfig.caFile` | `kubeApiServer.tlsConfig.ca` |
| `kubeControllerManager.serviceMonitor.insecureSkipVerify` / `.serverName` and hard-coded `.caFile` | `kubeControllerManager.serviceMonitor.tlsConfig` |
| `kubeScheduler.serviceMonitor.insecureSkipVerify` / `.serverName` and hard-coded `.caFile` | `kubeScheduler.serviceMonitor.tlsConfig` |
| Hard-coded kube-proxy `tlsConfig.caFile` | `kubeProxy.serviceMonitor.tlsConfig.ca` |
| `kubeEtcd.serviceMonitor.insecureSkipVerify` / `.serverName` / `.caFile` / `.certFile` / `.keyFile` | `kubeEtcd.serviceMonitor.tlsConfig` |

`kubeControllerManager` and `kubeScheduler` now default to a literal `tlsConfig.insecureSkipVerify: true`. This matches the value that the previous Kubernetes-version-dependent logic selected for every Kubernetes version supported by the chart.

Helm deep-merges values. When replacing a default `tlsConfig.ca.configMap` with a Secret, explicitly set `tlsConfig.ca.configMap: null` in addition to configuring `tlsConfig.ca.secret`.

The Target Allocator reads Secret-backed endpoint credentials and sends them to Collectors. Its ServiceAccount must have permission to read the referenced Secrets; the chart's default ClusterRole already provides that access. Enable `collectors.<name>.targetAllocator.mtls.enabled`, as in the `prometheus-otel` example, to protect credentials in transit. Alternatively, use `allowInsecureAuthSecrets` only when transport security is provided separately.

## 0.19.0 to 0.19.1

> [!WARNING]
> The new component names only work with Collector images that recognize them. If you pin an older Collector image, set `rewriteDeprecatedComponentNames: false` (see below).

The chart now generates collector components using their new (non-deprecated) names to avoid the Collector's deprecation warning logs, for example `hostmetrics` -> `host_metrics` and `k8sattributes` -> `k8s_attributes`. See [#2282](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/2282).

The new root-level value `rewriteDeprecatedComponentNames` (default `true`) also rewrites any deprecated component names found in your own `collector.config` to the new names before presets are merged. If both the old and new spelling are present for the same component, the new name wins and the old one is dropped. Please rename the components in your `collector.config` to their new names directly; the auto-rewrite will be removed in a future chart release.

If you are using a Collector image that does not recognize the new component names, set `rewriteDeprecatedComponentNames: false` to preserve the old names:

```yaml
rewriteDeprecatedComponentNames: false
```

## 0.6.x to 0.7.x

Version 0.7.0 has unified the previous collectors (daemonset and deployment) in a single one. If you are using custom configurations for `cluster` collector, you will need to merge your `cluster` collector configuration with `daemon` collector and remove `collectors.cluster` section from your values file.
If you are using helm, upgrade command is enough the prune old resources, but gitops approaches like 'ArgoCD' could require to select pruning options during sync process to get rid of removed resources.
