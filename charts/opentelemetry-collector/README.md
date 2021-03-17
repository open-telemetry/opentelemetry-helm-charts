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

## Configuration

### Default configuration

By default this chart will deploy an OpenTelemetry Collector as daemonset with three pipelines (logs, metrics and traces)
and logging exporter enabled by default. Besides daemonset (agent), it can be also installed as standalone deployment.
Both modes can be enabled together, in that case logs, metrics and traces will be flowing from agents to standalone collectors.

*Example*: Install collector as a standalone deployment, and do not run it as an agent.

```yaml
agentCollector:
  enabled: false
standaloneCollector:
  enabled: true
```

By default collector has the following receivers enabled:

- **metrics**: OTLP and prometheus. Prometheus is configured only for scraping collector's own metrics.
- **traces**: OTLP, zipkin and jaeger (thrift and grpc).
- **logs**: OTLP (to enable container logs, see [Configuration for Kubernetes container logs](#configuration-for-kubernetes-container-logs)).

There are two ways to configure collector pipelines, which can be used together as well.

### Basic top level configuration

*Example*: Disable metrics pipeline and send traces to zipkin exporter:

```yaml
config:
  exporters:
    zipkin:
      endpoint: zipkin-all-in-one:14250
  service:
    pipelines:
      metrics: null
      traces:
        exporters:
          - zipkin
```

### Configuration with `agentCollector` and `standaloneCollector` properties

`agentCollector` and `standaloneCollector` properties allow to override collector configurations
and default parameters applied on the k8s pods.

`agentCollector(standaloneCollector).configOverride` property allows to provide an extra
configuration that will be merged into the default configuration.

*Example*: Enable host metrics receiver on the agents:

```yaml
agentCollector:
  configOverride:
    receivers:
      hostmetrics:
        scrapers:
          cpu:
          load:
          memory:
          disk:
    service:
      pipelines:
        metrics:
          receivers: [prometheus, hostmetrics]
  extraEnvs:
  - name: HOST_PROC
    value: /hostfs/proc
  - name: HOST_SYS
    value: /hostfs/sys
  - name: HOST_ETC
    value: /hostfs/etc
  - name: HOST_VAR
    value: /hostfs/var
  - name: HOST_RUN
    value: /hostfs/run
  - name: HOST_DEV
    value: /hostfs/dev
  extraHostPathMounts:
  - name: hostfs
    hostPath: /
    mountPath: /hostfs
    readOnly: true
    mountPropagation: HostToContainer
```

### Configuration for Kubernetes container logs

The collector can be used to collect logs sent to standard output by Kubernetes containers.
This feature is disabled by default. It has the following requirements:

- It needs agent collector to be deployed, which means it will not work if only standalone collector is enabled.
- It requires the [contrib](https://github.com/open-telemetry/opentelemetry-collector-contrib) version
of the collector image.

To enable this feature, set the  `agentCollector.containerLogs.enabled` property to `true` and replace the collector image.
Here is an example `values.yaml`:

```yaml
agentCollector:
  containerLogs:
    enabled: true

image:
  repository: otel/opentelemetry-collector-contrib

command:
  name: otelcontribcol
```

The way this feature works is it adds a `filelog` receiver on the `logs` pipeline. This receiver is preconfigured
to read the files where Kubernetes container runtime writes all containers' console output to.

#### :warning: Warning: Risk of looping the exported logs back into the receiver, causing "log explosion"

The container logs pipeline uses the `logging` console exporter by default.
Paired with the default `filelog` receiver that receives all containers' console output,
it is easy to accidentally feed the exported logs back into the receiver.

Also note that using the `--log-level=debug` option for the `logging` exporter causes it to output
multiple lines per single received log, which when looped, would amplify the logs exponentially.

To prevent the looping, the default configuration of the receiver excludes logs from the collector's containers.

If you want to include the collector's logs, make sure to replace the `logging` exporter
with an exporter that does not send logs to collector's standard output.

Here's an example `values.yaml` file that replaces the default `logging` exporter on the `logs` pipeline
with an `otlphttp` exporter that sends the container logs to `https://example.com:55681` endpoint.
It also clears the `filelog` receiver's `exclude` property, for collector logs to be included in the pipeline.

```yaml
agentCollector:
  containerLogs:
    enabled: true

  configOverride:
    exporters:
      otlphttp:
        endpoint: https://example.com:55681
    receivers:
      filelog:
        exclude: []
    service:
      pipelines:
        logs:
          exporters:
            - otlphttp

image:
  repository: otel/opentelemetry-collector-contrib

command:
  name: otelcontribcol
```

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.
