# Upgrade guidelines

## 0.24.6 to 0.25.0

The chart now installs Operator 0.161.0. Since Operator 0.160.0, the `operator.networkpolicy` and `operand.networkpolicy` feature gates are disabled by default. See the [Operator 0.160.0 release notes](https://github.com/open-telemetry/opentelemetry-operator/releases/tag/v0.160.0).

Upgrading does not remove the NetworkPolicies that earlier versions created:

- The `opentelemetry-operator` NetworkPolicy keeps the API server IPs from when it was created. If those IPs change, the Operator can no longer reach the API server.
- A collector keeps its NetworkPolicy if the Operator webhook set `spec.networkPolicy.enabled: true` on it.

To remove them:

```sh
kubectl delete networkpolicy opentelemetry-operator -n <operator-namespace>
kubectl patch opentelemetrycollector <name> -n <namespace> --type merge -p '{"spec":{"networkPolicy":{"enabled":false}}}'
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
