# Upgrade guidelines

## 0.25.x to 0.26.2

Version 0.26.2 allows the bundled Kubernetes component ServiceMonitors to work with the Target Allocator's `denyFSAccessThroughSMs: true` setting by using Secret-backed tokens and Secret/ConfigMap TLS references. File-backed credentials remain the default; no credential migration is needed unless you enable this restriction.

Before enabling it, configure each enabled component:

1. **Replace token files.** Set `serviceMonitor.bearerTokenFile: ""` and configure `serviceMonitor.authorization` with `type: Bearer` and `credentials.name` / `credentials.key` pointing to a token Secret in the ServiceMonitor's namespace. For endpoints that need no authentication, clear `bearerTokenFile` and leave `authorization: null`.
2. **Replace TLS files.** For HTTPS scrapes, replace CA, client certificate, and private key file paths with `tlsConfig.ca`, `.cert`, and `.keySecret` references. This includes the implicit service-account CA file: configure a `ca` reference, such as the `kube-root-ca.crt` ConfigMap. Use `kubeApiServer.tlsConfig` for kube-apiserver and `<component>.serviceMonitor.tlsConfig` for the other TLS-enabled components. Clear any corresponding direct `serviceMonitor.caFile`, `.certFile`, or `.keyFile` settings.
3. **Enable mTLS between the Target Allocator and Collectors** with `collectors.<name>.targetAllocator.mtls.enabled: true` to protect Secret-backed credentials in transit. Set `mtls.useCertManager: true` if cert-manager will supply the certificates.

To have the chart create the metrics ServiceAccount and token Secret, enable both `kubernetesServiceMonitors.enabled` and `kubernetesServiceMonitors.authorization.create`, then reference that Secret in the authenticated components' authorization settings.

Enable `collectors.<name>.targetAllocator.prometheusCR.denyFSAccessThroughSMs: true` only after **all discovered ServiceMonitors** are free of credential file references. The Target Allocator rejects monitors that still reference files, and their metrics will not be scraped.

See the [prometheus-otel example](examples/prometheus-otel/values.yaml) for the complete configuration, including token Secret references, TLS settings, and mTLS setup.

## 0.24.6 to 0.25.0

The chart now installs Operator 0.161.0. Since Operator 0.160.0, the `operator.networkpolicy` and `operand.networkpolicy` feature gates are disabled by default. See the [Operator 0.160.0 release notes](https://github.com/open-telemetry/opentelemetry-operator/releases/tag/v0.160.0).

Upgrading does not remove the NetworkPolicies that earlier versions created:

- The `opentelemetry-operator` NetworkPolicy keeps the API server IPs from when it was created. If those IPs change, the Operator can no longer reach the API server.
- A collector or TargetAllocator keeps its NetworkPolicy if the Operator webhook set `spec.networkPolicy.enabled: true` on it.

To remove them:

```sh
kubectl delete networkpolicy opentelemetry-operator -n <operator-namespace>
kubectl patch opentelemetrycollector <name> -n <namespace> --type merge -p '{"spec":{"networkPolicy":{"enabled":false}}}'
kubectl patch targetallocator <name> -n <namespace> --type merge -p '{"spec":{"networkPolicy":{"enabled":false}}}'
```

To keep creating NetworkPolicies, enable the feature gates:

```yaml
opentelemetry-operator:
  manager:
    featureGatesMap:
      operator.networkpolicy: true
      operand.networkpolicy: true
```

## 0.24.2 to 0.24.3

Default resource requests and limits were removed from `defaultCRConfig.resources` and `collectors.daemon.resources`. If you relied on these defaults, set them explicitly in your values. To retain the previous defaults:

```yaml
defaultCRConfig:
  resources:
    requests:
      memory: "64Mi"
      cpu: "250m"
    limits:
      memory: "128Mi"
      cpu: "250m"

collectors:
  daemon:
    resources:
      limits:
        cpu: 200m
        memory: 500Mi
      requests:
        cpu: 100m
        memory: 250Mi
```

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
