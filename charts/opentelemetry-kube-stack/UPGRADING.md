# Upgrade guidelines

## 0.23.x to 0.24.x

This release adds opt-in Secret-backed authorization and Secret/ConfigMap TLS references for Kubernetes component ServiceMonitors. These allow scraping with `targetAllocator.prometheusCR.denyFSAccessThroughSMs: true` when all filesystem credential references are removed. The chart can also create a dedicated ServiceAccount and token Secret for metrics scraping.

By default, `serviceMonitor.authorization: false` retains the existing bearer token file at `/var/run/secrets/kubernetes.io/serviceaccount/token`. Existing direct `serviceMonitor` TLS settings remain supported; non-null `insecureSkipVerify` and `serverName` values override their nested equivalents. The nested interface uses `SafeTLSConfig` and does not accept `caFile`, `certFile`, or `keyFile`.

> [!WARNING]
> **If any discovered Kubernetes component ServiceMonitor has `authorization: false`, its Collectors CANNOT set `targetAllocator.prometheusCR.denyFSAccessThroughSMs: true`. Leave this setting `false`.** The Target Allocator rejects ServiceMonitors referencing filesystem credentials, so their targets will not be scraped. TLS file references (`caFile`, `certFile`, or `keyFile`) also require `denyFSAccessThroughSMs: false`, even with Secret-backed authorization.

To opt in and enable `denyFSAccessThroughSMs: true`:

- Configure `serviceMonitor.authorization` with `type: Bearer` and `credentials.name` / `credentials.key` referencing a token Secret. Use `authorization: null` for endpoints requiring no authentication; this omits the bearer token file too.
- Replace TLS file paths with `tlsConfig.ca`, `.cert`, and `.keySecret` references. Use `kubeApiServer.tlsConfig` for kube-apiserver and `serviceMonitor.tlsConfig` for other components. Configuring `ca` replaces the implicit service-account CA file fallback. Etcd has no implicit CA file. Remove any corresponding direct `serviceMonitor.caFile`, `.certFile`, or `.keyFile` settings; an explicit file path and its nested reference are mutually exclusive.
- **You MUST enable `collectors.<name>.targetAllocator.mtls.enabled` for every Collector receiving Secret-backed credentials from the Target Allocator.** These credentials are transmitted to Collectors and require mTLS protection.

The `prometheus-otel` example demonstrates this configuration.

For a chart-managed token Secret, enable `kubernetesServiceMonitors.enabled` and `kubernetesServiceMonitors.authorization.create` (defaults to `false`). This creates a dedicated ServiceAccount, a long-lived token Secret, and RBAC allowing `GET /metrics`. Configure each authenticated component explicitly:

```yaml
kubeApiServer:
  serviceMonitor:
    authorization:
      type: Bearer
      credentials:
        name: '{{ include "opentelemetry-kube-stack.kubernetesMetrics.tokenSecretName" . }}'
        key: token
```

Override generated names with `kubernetesServiceMonitors.authorization.serviceAccountName` and `.secretName`, or leave `create: false` and reference your own Secret. Rendering fails if a ServiceMonitor references the chart-managed Secret while its creation is disabled.

Secrets must share their ServiceMonitor's namespace, normally the release namespace. With `ignoreNamespaceSelectors: true`, chart-managed credentials are created in `default` and `kube-system`. The chart defaults `targetAllocator.prometheusCR.secretNamespaces` to these namespaces unless explicitly configured. The default ClusterRole permits the Target Allocator to read these Secrets.

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
