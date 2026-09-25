# Upgrade guidelines

These upgrade guidelines only contain instructions for version upgrades which require manual modifications on the user's side.
If the version you want to upgrade to is not listed here, then there is nothing to do for you.
Just upgrade and enjoy.

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
