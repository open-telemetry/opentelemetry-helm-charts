# Upgrade guidelines

These upgrade guidelines only contain instructions for version upgrades which require manual modifications on the user's side.
If the version you want to upgrade to is not listed here, then there is nothing to do for you.
Just upgrade and enjoy.

## 0.16.4 to 0.17.0

Custom `podLabels` are no longer part of the DaemonSet and Service selectors,
so changing them updates the Pods instead of failing with
`spec.selector: ... field is immutable`. They are also no longer added to the
labels of the other objects the chart renders (DaemonSet, Service,
ServiceMonitor, ConfigMap, ServiceAccount and RBAC objects); only the Pods
carry them.

If you do not set `podLabels`, nothing changes. If you do, the DaemonSet
selector changes once, which Kubernetes rejects on an existing DaemonSet.
Delete the DaemonSet without deleting its Pods before upgrading; the upgraded
DaemonSet then replaces the old Pods:

```console
kubectl delete daemonset <release>-opentelemetry-ebpf-instrumentation --namespace <namespace> --cascade=orphan
helm upgrade <release> open-telemetry/opentelemetry-ebpf-instrumentation --namespace <namespace>
```

Use the DaemonSet name from `kubectl get daemonset` if you set
`fullnameOverride` or `nameOverride`.

## 0.16.2 to 0.16.3

Previously ignored `podSecurityContext` values now take effect in the DaemonSet
pod spec. Before upgrading, review existing values, including whether your
environment requires a pod-level `runAsUser` alongside `runAsGroup` to allow pods
to start. Choose a user ID appropriate for your environment and security policy.

## 0.13.1 to 0.14.0

The chart-managed default configuration now uses OBI Config v2. The effective
export destinations, Prometheus port, Kubernetes enrichment, and preset
behavior remain equivalent to the previous chart defaults.

Existing non-empty Config v1 values remain supported. The chart detects Config
v2 from `config.data.extensions.obi.version: "2.0"`; data without that marker is
merged with the legacy Config v1 defaults. Empty `config.data` now selects the
new Config v2 defaults.

Config v2 does not automatically apply legacy `OTEL_EBPF_*` environment
variables. Move those values to their canonical Config v2 fields and reference
environment-backed values explicitly with `${VAR}`. Follow the upstream OBI
[Config v1 to v2 migration guide](https://opentelemetry.io/docs/zero-code/obi/configure/migrate-to-config-v2/)
when converting custom configuration.

The Config v2 Prometheus pull exporter uses `/metrics`; it does not expose the
Config v1 `prometheus_export.path` setting. Override
`serviceMonitor.metrics.endpoint.path` when the scraper needs a different path.

## 0.9.3 to 0.9.4

The `tpl` function has been added to `.Values.config.data`. If you are currently using any `{{ }}` syntax in `.Values.config.data` it will now be rendered. To escape existing instances of `{{ }}`, use ``` {{` <original content> `}} ```. For example, `{{ REDACTED_EMAIL }}` becomes ``` {{` {{ REDACTED_EMAIL }} `}} ```.
