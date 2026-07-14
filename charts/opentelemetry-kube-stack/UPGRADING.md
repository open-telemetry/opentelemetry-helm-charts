# Upgrade guidelines

These upgrade guidelines only contain instructions for version upgrades which require manual modifications on the user's side.
If the version you want to upgrade to is not listed here, then there is nothing to do for you.
Just upgrade and enjoy.

## 0.19.0 to 0.19.1

> [!WARNING]
> The new component names only work with Collector images that recognize them. If you pin an older Collector image, set `rewriteDeprecatedComponentNames: false` (see below).

The chart now generates collector components using their new (non-deprecated) names to avoid the Collector's deprecation warning logs, for example `hostmetrics` -> `host_metrics` and `k8sattributes` -> `k8s_attributes`. See [#2282](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/2282).

The new root-level value `rewriteDeprecatedComponentNames` (default `true`) also rewrites any deprecated component names found in your own `collector.config` to the new names before presets are merged. If both the old and new spelling are present for the same component, the new name wins and the old one is dropped. Please rename the components in your `collector.config` to their new names directly; the auto-rewrite will be removed in a future chart release.

If you are using a Collector image that does not recognize the new component names, set `rewriteDeprecatedComponentNames: false` to preserve the old names:

```yaml
rewriteDeprecatedComponentNames: false
```
