# Upgrade guidelines

> [!NOTE]
> The OpenTelemetry Demo does not support being upgraded from one version to
> another. If you need to upgrade the chart, you must first delete the existing
> release and then install the new version.


## To 0.41

This release follows the OpenTelemetry Demo application's `3.0.0` release and
brings in ~270 upstream commits. Given the note above, this is a full
reinstall, but the following changes are worth knowing about since they affect
any custom `values.yaml` overrides you maintain.

### Removed components

* `product-reviews` and its mock `llm` backend have been removed entirely
  (including the `reviews` schema previously created in the Postgres init
  script). Any custom values overriding `components.product-reviews` or
  `components.llm` must be removed.

### Postgres renamed and re-credentialed

The `postgresql` component has been renamed to `astronomy-db` to match
upstream, and its credentials changed:

* Superuser: still the default `postgres` user, password `changeit`
  (previously `POSTGRES_USER=root`/`POSTGRES_PASSWORD=otel`).
* Application user/database: `astronomy_user`/`astronomy_db` with password
  `astronomy_password` (previously `otelu`/`otel` with password `otelp`).
  `product-catalog` and `accounting`'s `DB_CONNECTION_STRING` values have been
  updated to match.
* A new `monitoring_user`/`monitoring_password` (with the `pg_monitor` role)
  is used by the collector's annotation-discovered `postgresql` metrics
  scrape instead of the old `root`/`otel` credentials.

If you override `components.postgresql` in your own values, rename it to
`components.astronomy-db` and update any credentials/connection strings your
own services use to reach it.

### Load generator: Locust replaced with k6

The `load-generator` component now runs [k6](https://k6.io/) (via the
`xk6-otel` extension) instead of Locust. All `LOCUST_*` environment variables
have been removed (there is no longer a web UI or exposed port) and replaced
with `LOAD_GENERATOR_VUS`, `K6_TARGET_URL`, and `K6_OTEL_*` variables. The
`frontend-proxy`'s `LOCUST_WEB_HOST`/`LOCUST_WEB_PORT` routing has also been
removed.

### flagd OTLP configuration

`flagd`'s native `FLAGD_METRICS_EXPORTER`/`FLAGD_OTEL_COLLECTOR_URI`
environment variables have been replaced with the standard
`OTEL_EXPORTER_OTLP_ENDPOINT`/`OTEL_EXPORTER_OTLP_PROTOCOL` (`http/protobuf`)
variables, and the image bumped to `v0.16.0`.

### New components

* `telemetry-docs`: serves Weaver-generated telemetry schema documentation.
* `opamp-server`: an OpAMP server the Collector now reports status, health,
  and effective config to via the new `opamp` extension.
* `agent`, `mcp`, `chatbot`: a new AI shopping-assistant stack (LangGraph
  agent, an MCP tool server, and a Gradio chat UI). `API_KEY` defaults to
  empty and `LLM_BASE_URL`/`LLM_MODEL` default to a placeholder endpoint —
  set these to point at a real LLM provider to use the assistant.
* `firepit` and `otel-ebpf-profiler`: optional profiling stack, added
  **disabled by default**.
  * `firepit` is a regular `components.firepit` entry, same as any other demo
    component.
  * `otel-ebpf-profiler` is a **second, separate instance of the
    `opentelemetry-collector` chart** (an aliased dependency in `Chart.yaml`,
    configured under the top-level `otel-ebpf-profiler` key, not under
    `components`), since eBPF profiling needs privileged/hostPID access that
    shouldn't be granted to the collector already handling metrics/traces/logs.
    It uses the chart's built-in `presets.profiling`
    ([open-telemetry/opentelemetry-helm-charts#2126](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/2126)),
    which automatically wires the `profiling` receiver, a privileged
    `securityContext`, `hostPID`, and the `tracefs` hostPath mount — no manual
    volume/securityContext wiring needed.
  * The **main** Collector already carries `--feature-gates=service.profilesSupport`,
    a `profiles` pipeline, and an `otlp_grpc/firepit` exporter unconditionally
    (harmless when the stack is disabled — the pipeline just has nothing
    feeding it). So enabling `firepit` and `otel-ebpf-profiler` is enough on
    its own; no other Collector changes are needed to see profiling data flow.

### OpenTelemetry Collector config

* Exporters renamed: `otlp/jaeger` → `otlp_grpc/jaeger`,
  `otlphttp/prometheus` → `otlp_http/prometheus`. If you override the
  traces/metrics pipelines' `exporters` lists, update the names.
* The `spanmetrics` connector was renamed to `span_metrics`.
* A new `prometheus/ad` receiver scrapes a `/metrics` endpoint now exposed by
  `ad` on port `9465`.
* A new `gen_ai_normalizer` processor normalizes OpenLLMetry/Traceloop GenAI
  attributes (emitted by `agent`/`mcp`/`chatbot`) into GenAI semconv
  attributes.
* `checkout`, `shipping`, and `flagd` now export OTLP over `http/protobuf` to
  the Collector's HTTP port (`4318`) instead of gRPC (`4317`).

### Other changes

* `checkout`, `product-catalog`, and `shipping` now run with
  `readOnlyRootFilesystem: true` plus a `/tmp` `emptyDir` mount.
* `checkout`, `accounting`, and `fraud-detection` gained a `KAFKA_TOPIC`
  environment variable (defaulting to `orders`) to configure the Kafka topic
  name.
* `valkey-cart`'s image moved from `valkey/valkey` to `ghcr.io/valkey-io/valkey`
  (tag `9.0.4-alpine3.23`).
* `default.env` now includes a base `OTEL_RESOURCE_ATTRIBUTES=service.namespace=otel-demo`
  entry, and most components set a `service.criticality=<low|medium|high|critical>`
  value via `envOverrides`' `OTEL_RESOURCE_ATTRIBUTES_EXTRA` mechanism, matching
  upstream. If you already set your own `OTEL_RESOURCE_ATTRIBUTES` override for a
  component, be aware it will now be combined with this base value rather than
  standing alone.

## To 0.40.4

The `transform` processor now uses the `set_semconv_span_name()` function to
reduce span metrics cardinality explosion caused by high-cardinality span names.
See the [processor documentation](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/transformprocessor#set_semconv_span_name)
and [troubleshooting guide](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/connector/spanmetricsconnector/README.md#troubleshooting-span-metrics-high-cardinality)
for details.

## To 0.40

The product catalog has been moved to use a Postgres database. Custom products
(and product reviews) can be specified with your own init-db.sql script
contained in a custom ConfigMap, and referenced for the Postgres component.

The Jaeger sub-chart was upgraded to 4.3, which included several breaking
changes to prior configurations.

Support for `podLabels` has been added to all components.

## To 0.39

Support for IPv6 environments was introduced to the demo.

## To 0.38

A new postgresql container was introduced to the demo.

## To 0.36

The Demo 2.0 release removed the `service` suffix from many components names,
and renamed some components based on a naming standard defined in
the [#1788](https://github.com/open-telemetry/opentelemetry-demo/issues/1788)
issue in the OpenTelemetry Demo repository. Any custom configuration for a Demo
component that was renamed will need to be updated to use the new name. The
following table shows the old and new names for each component:

| Old Name               | New Name        |
| ---------------------- | --------------- |
| accountingservice      | accounting      |
| adservice              | ad              |
| cartservice            | cart            |
| checkoutservice        | checkout        |
| currencyservice        | currency        |
| emailservice           | email           |
| flagd                  | flagd           |
| flagd-ui               | flagd-ui        |
| frauddetectionservice  | fraud-detection |
| frontend               | frontend        |
| frontendproxy          | frontend-proxy  |
| frontend-web           | frontend-web    |
| grafana                | grafana         |
| imageprovider          | image-provider  |
| jaeger                 | jaeger          |
| kafka                  | kafka           |
| loadgenerator          | load-generator  |
| opensearch             | opensearch      |
| otelcollector          | otel-collector  |
| paymentservice         | payment         |
| productcatalogservice  | product-catalog |
| prometheus             | prometheus      |
| quotesservice          | quote           |
| recommendationsservice | recommendation  |
| shippingservice        | shipping        |
| valkey-cart            | valkey-cart     |

## To 0.35

The Helm chart release name prefix has been removed from all resources. If you
have any custom configuration that depend on the release name, you will need to
update it accordingly.

## To 0.33

The Helm prerequisite version has been updated to Helm 3.14+. Please upgrade your
Helm client to the latest version.

## To 0.28

The `configuration` property for components has been removed in favor of the new `mountedConfigMaps` property.
This new property allows you to specify the contents of the configuration using the `data` sub-property. You will also
need to specify the `mountPath` to use, and give the configuration a name. The old `configuration` property used
`/etc/config` and `config` as values for these respectively. The following example shows how to migrate from the old
`configuration` property to the new `mountedConfigMaps` property:

```yaml
# Old configuration property
configuration:
  my-config.yaml: |
    # Contents of my-config.yaml

# New mountedConfigMaps property
mountedConfigMaps:
  - name: config
    mountPath: /etc/config
    data:
      my-config.yaml: |
        # Contents of my-config.yaml
```

## To 0.24

This release uses the [kubernetes attributes processor](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/k8sattributesprocessor)
to add kubernetes metadata as resource attributes. If you override the processors array in your config, you will
need to add the k8s attributes processor manually to restore `service.instance.id`
resource attribute.

## To 0.23

The Prometheus sub-chart dependency made updates to pod labels. You may need to
use the `--force` option with your Helm upgrade command, or delete the release
and re-install it.

## To 0.22

This release moves to using the `connectors` functionality in the OpenTelemetry
Collector. The `spanmetrics` processor has been moved to use `connectors`
which results in an additional required exporter in the `traces` pipeline.
Existing releases that override `exporters` in the `traces` pipeline, will
need to add `spanmetrics` to the list of exporters before upgrading. The
OpenTelemetry Collector will fail to start otherwise.

## To 0.21

The deployment labelSelector `app.kubernetes.io/name` has been renamed to
individual workload naming. If you upgrade it from charts <= 0.20, you
will have to delete all existing opentelemetry-demo deployments before running
`helm upgrade` command.

## To 0.20

The `observability.<sub chart>.enabled` parameters have been moved to an
`enabled` parameter within the sub chart itself. If you had changes to these
parameters, you will need to update your changes to work with the new structure.

## To 0.18

The `serviceType` and `servicePort` parameters have been moved under a `service`
parameter with names of `type` and `port` respectively. If you had changes to
these parameters for any demo component, you will need to update your changes
to work with the new structure for the `service` parameter.

## To 0.13

Jaeger was moved to a Helm sub-chart instead of a local chart deployment. If you
had changes specified to the `observability.jaeger` parameter, those changes
will need to be re-implemented as sub-chart parameters under the top level
`jaeger` parameter instead.
