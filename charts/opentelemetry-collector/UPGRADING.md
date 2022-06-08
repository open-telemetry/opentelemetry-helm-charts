# Upgrade guidelines

## 0.18.0 to 0.19.0

[Remove agentCollector and standaloneCollector settings](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/216)

The `agentCollector` and `standaloneCollector` config sections have been removed.  Upgrades/installs of chart 0.19.0 will fail if `agentCollector` or `standaloneCollector` are in the values.yaml.  See the [Migrate to mode](#migrate-to-mode) steps for instructions on how to replace `agentCollector` and `standaloneCollector` with `mode`.

## 0.13.0 to 0.14.0

[Remove two-deployment mode](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/159)

The ability to install both the agent and standalone collectors simultaneous with the chart has been removed.  Installs/upgrades where both  `.Values.agentCollector.enabled` and `.Values.standloneCollector.enables` are true will fail.  `agentCollector` and `standloneCollector` have also be deprecated, but backward compatibility has been maintained.

### To run both a deployment and daemonset

Install a deployment version of the collector. This is done by setting `.Values.mode` to `deployment`

```yaml
mode: deployment
```

Next, install an daemonset version of the collector that is configured to send traffic to the previously installed deployment.  This is done by setting `.Values.mode` to `daemonset` and updating `.Values.config` so that data is exported to the deployment.

```yaml
mode: daemonset

config:
  exporters:
    otlp:
      endpoint: example-opentelemetry-collector:4317
      tls:
        insecure: true
  service:
    pipelines:
      logs:
        exporters:
         - otlp
         - logging
      metrics:
        exporters:
         - otlp
         - logging
      traces:
        exporters:
         - otlp
         - logging
```

See the [daemonset-and-deployment](examples/daemonset-and-deployment) example to see the rendered config.

### Migrate to `mode`:

The `agentCollector` and `standaloneCollector` sections in values.yaml have been deprecated. Instead there is a new field, `mode`, that determines if the collector is being installed as a daemonset or deployment.  

```yaml
# Valid values are "daemonset" and "deployment".
# If set, agentCollector and standaloneCollector are ignored.
mode: <daemonset|deployment>
```

The following fields have also been added to the root-level to replace the depracated `agentCollector` and `standaloneCollector` settings.

```yaml
containerLogs:
  enabled: false

resources:
  limits:
    cpu: 1
    memory: 2Gi

podAnnotations: {}

podLabels: {}

# Host networking requested for this pod. Use the host's network namespace.
hostNetwork: false

# only used with deployment mode
replicaCount: 1

annotations: {}
```

When using `mode`, these settings should be used instead of their counterparts in `agentCollector` and `standaloneCollector`.

Set `mode` to `daemonset` if `agentCollector` was being used.  Move all `agentCollector` settings to the corresponding root-level setting.  If `agentCollector.configOverride` was being used, merge the settings with `.Values.config`.

Example agentCollector values.yaml:

```yaml
agentCollector:
  resources:
    limits:
      cpu: 3
      memory: 6Gi
  configOverride:
    receivers:
      hostmetrics:
        scrapers:
          cpu:
          disk:
          filesystem:
    service:
      pipelines:
        metrics:
          receivers: [otlp, prometheus, hostmetrics]
```

Example mode values.yaml:

```yaml
mode: daemonset

resources:
  limits:
    cpu: 3
    memory: 6Gi

config:
  receivers:
    hostmetrics:
      scrapers:
        cpu:
        disk:
        filesystem:
  service:
    pipelines:
      metrics:
        receivers: [otlp, prometheus, hostmetrics]
```

Set `mode` to `deployment` if `standaloneCollector` was being used.  Move all `standaloneCollector` settings to the corresponding root-level setting.  If `standaloneCollector.configOverride` was being used, merge the settings with `.Values.config`.

Example standaloneCollector values.yaml:

```yaml
standaloneCollector:
  enabled: true
  replicaCount: 2
  configOverride:
    receivers:
      podman_stats:
        endpoint: unix://run/podman/podman.sock
        timeout: 10s
        collection_interval: 10s
    service:
      pipelines:
        metrics:
          receivers: [otlp, prometheus, podman_stats]
```

Example mode values.yaml:

```yaml
mode: deployment

replicaCount: 2

config:
  receivers:
    receivers:
      podman_stats:
        endpoint: unix://run/podman/podman.sock
        timeout: 10s
        collection_interval: 10s
  service:
    pipelines:
      metrics:
        receivers: [otlp, prometheus, podman_stats]
```

Default configuration in `.Values.config` can now be removed with `null`.  When changing a pipeline, you must explicitly list all the components that are in the pipeline, including any default components.

*Example*: Disable metrics and logging pipelines and non-otlp receivers:

```yaml
config:
  receivers:
    jaeger: null
    prometheus: null
    zipkin: null
  service:
    pipelines:
      traces:
        receivers:
          - otlp
      metrics: null
      logs: null
```
