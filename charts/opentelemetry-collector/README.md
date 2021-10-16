# OpenTelemetry Collector Helm Chart

The helm chart installs [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)
in kubernetes cluster.

## Prerequisites

- Helm 3.0+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-opentelemetry-collector, run the following command:

```console
helm install my-opentelemetry-collector open-telemetry/opentelemetry-collector
```

### Upgrading from 0.6.0

The chart has changed radically from version 0.6.0 to 0.7.0. Multiple deployments are no longer managed through a single
chart deployment and have been suppressed in favor of only doing one deployment at a time. This means if you chose to
set up `standaloneCollector` and `agentCollector` at the same time, you will now need to deployments.

Additionally, default configuration has been suppressed in favour of the user providing its own configuration on
install time. `config` attribute will now be set up from scratch.

Additional previously available configurations such as, container logs, host metrics and memory limit have been moved
into a feature flag map `enabledConfigPresets` which will inject the appropriate environment variables, configuration
sections and volume mounts as before. All these options are now disabled by default.

MemBallastSize option in the command line has been removed in newer versions of the collector, as this is now managed
through the config.

Now by default the chart uses 'opentelemetry-collector-contrib' as image, as opposed to the non-contrib image, as many
features supported by this chart depend on extra functionalities. To use the non-contrib image, set the following options:

```yaml
image:
  repository: otel/opentelemetry-collector
command:
  name: otelcol
```

#### Upgrading 0.6.0 agent only installation

To upgrade a chart installation with only `agentCollector` enabled:
```yaml
# No values supplied
```

The configuration would be akin in the new set up to:

<details>
<summary>Click to expand!</summary>

```yaml
enabledConfigurationPresets:
  memoryLimiter: true
resources:
  limits:
    cpu: 256m
    memory: 512Mi
config:
  exporters:
    logging:
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
    otlp:
      protocols:
        grpc:
        http:
    prometheus:
      config:
        scrape_configs:
          - job_name: opentelemetry-collector
            scrape_interval: 10s
            static_configs:
              - targets:
                  - localhost:8888
    zipkin:
      endpoint: 0.0.0.0:9411
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        exporters:
          - logging
        processors:
          - memorylimit/k8s
          - batch
        receivers:
          - otlp
      metrics:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
          - prometheus
      traces:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
          - jaeger
          - zipkin
ports:
  otlp:
    enabled: true
  jaeger-thrift:
    enabled: true
  jaeger-grpc:
    enabled: true
  zipkin:
    enabled: true
```

</details>

#### Upgrading 0.6.0 standalone only installation

If only standalone collector setup was used with:

```yaml
agentCollector:
  enabled: false
standaloneCollector:
  enabled: true
```
<details>
<summary>Click to expand!</summary>

```yaml
mode: deployment
enabledConfigurationPresets:
  memoryLimiter: true
resources:
  limits:
    cpu: 1
    memory: 2Gi
config:
  exporters:
    logging:
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
    otlp:
      protocols:
        grpc:
        http:
    prometheus:
      config:
        scrape_configs:
          - job_name: opentelemetry-collector
            scrape_interval: 10s
            static_configs:
              - targets:
                  - localhost:8888
    zipkin:
      endpoint: 0.0.0.0:9411
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        exporters:
          - logging
        processors:
          - memorylimit/k8s
          - batch
        receivers:
          - otlp
      metrics:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
          - prometheus
      traces:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
          - jaeger
          - zipkin
ports:
  otlp:
    enabled: true
  jaeger-thrift:
    enabled: true
  jaeger-grpc:
    enabled: true
  zipkin:
    enabled: true
```

</details>


###3 Upgrading 0.6.0 dual installation
If previously deployed the chart with double config, both agent and standalone collectors enabled, such as:

```yaml
standaloneCollector:
  enabled: true
```

Then the chart needs to be deployed twice, with the previously explained configs, plus an exporter section in the
"daemonset" mode deployment.

<details>
<summary>Click to expand!</summary>

```yaml
enabledConfigurationPresets:
  memoryLimiter: true
resources:
  limits:
    cpu: 256m
    memory: 512Mi
config:
  exporters:
    logging:
    otlp:  # NEW!
      endpoint: DEPLOYMENT_COLLECTOR_FULLNAME_SERVICE_HERE:4317
      insecure: true
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    jaeger:
      protocols:
        grpc:
          endpoint: 0.0.0.0:14250
        thrift_http:
          endpoint: 0.0.0.0:14268
    otlp:
      protocols:
        grpc:
        http:
    prometheus:
      config:
        scrape_configs:
          - job_name: opentelemetry-collector
            scrape_interval: 10s
            static_configs:
              - targets:
                  - localhost:8888
    zipkin:
      endpoint: 0.0.0.0:9411
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        exporters:
          - logging
          - otlp  # NEW!
        processors:
          - memorylimit/k8s
          - batch
        receivers:
          - otlp
      metrics:
        exporters:
          - logging
          - otlp  # NEW!
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
          - prometheus
      traces:
        exporters:
          - logging
          - otlp  # NEW!
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
          - jaeger
          - zipkin
ports:
  otlp:
    enabled: true
  jaeger-thrift:
    enabled: true
  jaeger-grpc:
    enabled: true
  zipkin:
    enabled: true
```

</details>


## Configuration

### Default configuration

By default, this chart will deploy an OpenTelemetry Collector as daemonset with no configuration. Hence, some basic
configuration is necessary for it to function.

### Basic top level configuration

* otlp receiver
* logging exporter
* health_check extension (LivenessProbe and ReadinessProbe depend on this)
* no monitoring for neither the collector
* visible through service

<details>
<summary>Click to expand!</summary>

```yaml
mode: deployment
config:
  exporters:
    logging:
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    otlp:
      protocols:
        grpc:
        http:
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        exporters:
          - logging
        processors:
          - batch
        receivers:
          - otlp
      metrics:
        exporters:
          - logging
        processors:
          - batch
        receivers:
          - otlp
      traces:
        exporters:
          - logging
        processors:
          - batch
        receivers:
          - otlp
ports:
  otlp:
    enabled: true
service:
  enabled: true
```

</details>

### Configuration for memory limit

For agent set up recommended values 256m and 512Mi:

<details>
<summary>Click to expand!</summary>

```yaml
# Default
# mode: daemonset
enabledConfigurationPresets:
  memoryLimiter: true
resources:
  limits:
    cpu: 256m
    memory: 512Mi
config:
  exporters:
    logging:
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    otlp:
      protocols:
        grpc:
        http:
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        exporters:
          - logging
        processors:
          - memorylimit/k8s
          - batch
        receivers:
          - otlp
      metrics:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
      traces:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
```

</details>

For standalone set up recommended values 1 cpu and 2Gi memory:

<details>
<summary>Click to expand!</summary>

```yaml
mode: deployment
enabledConfigurationPresets:
  memoryLimiter: true
resources:
  limits:
    cpu: 1
    memory: 2Gi
config:
  exporters:
    logging:
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    otlp:
      protocols:
        grpc:
        http:
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        exporters:
          - logging
        processors:
          - memorylimit/k8s
          - batch
        receivers:
          - otlp
      metrics:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
      traces:
        exporters:
          - logging
        processors:
          - memory_limiter/k8s
          - batch
        receivers:
          - otlp
```

</details>

### Relevant configuration for hostMetrics

This will only work in daemonset mode (Agent setup)

<details>
<summary>Click to expand!</summary>

```yaml
enabledConfigurationPresets:
  hostMetrics: true
config:
  exporters:
    logging:
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    otlp:
      protocols:
        grpc:
        http:
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        exporters:
          - logging
        processors:
          - batch
        receivers:
          - otlp
          - hostmetrics/k8s
      metrics:
        exporters:
          - logging
        processors:
          - batch
        receivers:
          - otlp
          - hostmetrics/k8s
      traces:
        exporters:
          - logging
        processors:
          - batch
        receivers:
          - otlp
          - hostmetrics/k8s
```

</details>

### Configuration for Kubernetes container logs

The collector can be used to collect logs sent to standard output by Kubernetes containers.
This feature is disabled by default. And only is supported in daemonset mode.

To enable this feature, set the  `enabledConfigPresets.containerLogs` property to `true`:

```yaml
enabledConfigPresets:
  containerLogs: true
```

The way this feature works is it adds a `filelog/k8s` receiver. This receiver is preconfigured
to read the files where Kubernetes container runtime writes all containers' console output to.

#### :warning: Warning: Risk of looping the exported logs back into the receiver, causing "log explosion"

The container logs pipeline uses the `logging` console exporter by default.
Paired with the `filelog/k8s` receiver that receives all containers' console output,
it is easy to accidentally feed the exported logs back into the receiver.

Also note that using the `--log-level=debug` option for the `logging` exporter causes it to output
multiple lines per single received log, which when looped, would amplify the logs exponentially.

To prevent the looping, the default configuration of the receiver excludes logs from the collector's containers.

If you want to include the collector's logs, make sure not to use the `logging` exporter so it doesn't send logs
to collector's standard output.

Here's an example `values.yaml` file that replaces the default `logging` exporter on the `logs` pipeline
with an `otlphttp` exporter that sends the container logs to `https://example.com:55681` endpoint.
It also clears the `filelog/k8s` receiver's `exclude` property, for collector logs to be included in the pipeline.

<details>
<summary>Click to expand!</summary>

```yaml
# Default mode
# mode: daemonset

enabledConfigPresets:
  containerLogs: true

config:
  exporters:
    otlphttp:
      endpoint: https://example.com:55681
  extensions:
    health_check:
  processors:
    batch:
  receivers:
    filelog/k8s:
      exclude: []
  service:
    extensions:
      - health_check
    pipelines:
      logs:
        receivers:
        - filelog/k8s
        processors:
        - batch
        exporters:
        - otlphttp
```

</details>

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.
