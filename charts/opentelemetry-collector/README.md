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
- **logs**: OTLP and logs from Kubernetes containers (see [Configuration for Kubernetes container logs](#configuration-for-kubernetes-container-logs)
  below).

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

The collector is preconfigured to receive logs sent to standard output by Kubernetes containers.

This feature needs agent collector to be deployed, which means it will not work if only standalone collector is enabled.

The feature can be disabled by setting the `agentCollector.containerLogs.enabled` property to `false`.

The preconfigured container logs pipeline uses `logging` console exporter by default.
To prevent looping the logs exported from collector back into the logs receiver,
the default configuration of the receiver excludes logs from the collector containers.
To change that, replace the exporter on the logs pipeline and remove the exclude on the logs receiver.

Here's an example `values.yaml` file that replaces the default `logging` exporter on the `logs` pipeline
with a `file` exporter that writes the container logs to `/var/log/container-logs/container-logs.json`.
It also sets the `exclude` property of `filelog` receiver to empty array, for collector logs not to be excluded.

```yaml
agentCollector:
  configOverride:
    exporters:
      file:
        path: /var/log/container-logs/container-logs.json
    receivers:
      filelog:
        exclude: []
    service:
      pipelines:
        logs:
          exporters:
            - file
  extraHostPathMounts:
    - name: varlogotclogs
      hostPath: /var/log/container-logs
      mountPath: /var/log/container-logs
      readOnly: false
```

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.
