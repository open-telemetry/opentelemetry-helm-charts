# OpenTelemetry Collector Helm Chart

The helm chart installs [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-opentelemetry-collector, run the following command:

```console
helm install my-opentelemetry-collector open-telemetry/opentelemetry-collector --set mode=<value>
```

Where the `mode` value needs to be set to one of `daemonset`, `deployment` or `statefulset`.

For an in-depth walk through getting started in Kubernetes using this helm chart, see [OpenTelemetry Kubernetes Getting Started](https://opentelemetry.io/docs/kubernetes/getting-started/).

## Upgrading

See [UPGRADING.md](UPGRADING.md).

## Security Considerations

OpenTelemetry Collector recommends to bind receivers' servers to addresses that limit connections to authorized users.
For this reason, by default the chart binds all the Collector's endpoints to the pod's IP.

More info is available in the [Security Best Practices docummentation](https://github.com/open-telemetry/opentelemetry-collector/blob/main/docs/security-best-practices.md#safeguards-against-denial-of-service-attacks)

Some care must be taken when using `hostNetwork: true`, as then OpenTelemetry Collector will listen on all the addresses in the host network namespace.

## Configuration

### Default configuration

By default this chart will deploy an OpenTelemetry Collector with three pipelines (logs, metrics and traces)
and logging exporter enabled by default. The collector can be installed either as daemonset (agent), deployment or stateful set.

*Example*: Install collector as a deployment.

```yaml
mode: deployment
```

By default collector has the following receivers enabled:

- **metrics**: OTLP and prometheus. Prometheus is configured only for scraping collector's own metrics.
- **traces**: OTLP, zipkin and jaeger (thrift and grpc).
- **logs**: OTLP (to enable container logs, see [Configuration for Kubernetes container logs](#configuration-for-kubernetes-container-logs)).

### Basic Top Level Configuration

The Collector's configuration is set via the `config` section. Default components can be removed with `null`. Remember that lists in helm are not merged, so if you want to modify any default list you must specify all items, including any default items you want to keep.

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

The chart also provides several presets, detailed below, to help configure important Kubernetes components. For more details on each component, see [Kubernetes Collector Components](https://opentelemetry.io/docs/kubernetes/collector/components/).

### Configuration for Kubernetes Container Logs

The collector can be used to collect logs sent to standard output by Kubernetes containers.
This feature is disabled by default. It has the following requirements:

- It needs agent collector to be deployed.
- It requires the [Filelog receiver](https://opentelemetry.io/docs/kubernetes/collector/components/#filelog-receiver) to be included in the collector, such as [contrib](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib) version of the collector image.

To enable this feature, set the  `presets.logsCollection.enabled` property to `true`.
Here is an example `values.yaml`:

```yaml
mode: daemonset

presets:
  logsCollection:
    enabled: true
    includeCollectorLogs: true
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
mode: daemonset

presets:
  logsCollection:
    enabled: true
    includeCollectorLogs: true

config:
  exporters:
    otlphttp:
      endpoint: https://example.com:55681
  service:
    pipelines:
      logs:
        exporters:
          - otlphttp
```

### Configuration for Kubernetes Attributes Processor

The collector can be configured to add Kubernetes metadata, such as pod name and namespace name, as resource attributes to incoming logs, metrics and traces. 

This feature is disabled by default. It has the following requirements:

- It requires the [Kubernetes Attributes processor](https://opentelemetry.io/docs/kubernetes/collector/components/#kubernetes-attributes-processor) to be included in the collector, such as [contrib](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib) version of the collector image.

To enable this feature, set the  `presets.kubernetesAttributes.enabled` property to `true`.
Here is an example `values.yaml`:

```yaml
mode: daemonset
presets:
  kubernetesAttributes:
    enabled: true
    # You can also configure the preset to add all of the associated pod's labels and annotations to you telemetry.
    # The label/annotation name will become the resource attribute's key.
    extractAllPodLabels: true
    extractAllPodAnnotations: true
```

### Configuration for Retrieving Kubelet Metrics

The collector can be configured to collect node, pod, and container metrics from the API server on a kubelet.

This feature is disabled by default. It has the following requirements:

- It requires the [Kubeletstats receiver](https://opentelemetry.io/docs/kubernetes/collector/components/#kubeletstats-receiver) to be included in the collector, such as [contrib](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib) version of the collector image.

To enable this feature, set the  `presets.kubeletMetrics.enabled` property to `true`.
Here is an example `values.yaml`:

```yaml
mode: daemonset
presets:
  kubeletMetrics:
    enabled: true
```

### Configuration for Kubernetes Cluster Metrics

The collector can be configured to collects cluster-level metrics from the Kubernetes API server. A single instance of this receiver can be used to monitor a cluster.

This feature is disabled by default. It has the following requirements:

- It requires the [Kubernetes Cluster receiver](https://opentelemetry.io/docs/kubernetes/collector/components/#kubernetes-cluster-receiver) to be included in the collector, such as [contrib](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib) version of the collector image.
- It requires statefulset or deployment mode with a single replica.

To enable this feature, set the  `presets.clusterMetrics.enabled` property to `true`.

Here is an example `values.yaml`:

```yaml
mode: deployment
replicaCount: 1
presets:
  clusterMetrics:
    enabled: true
```

### Configuration for Retrieving Kubernetes Events

The collector can be configured to collect Kubernetes events.

This feature is disabled by default. It has the following requirements:

- It requires [Kubernetes Objects receiver](https://opentelemetry.io/docs/kubernetes/collector/components/#kubernetes-objects-receiver) to be included in the collector, such as [contrib](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib) version of the collector image.

To enable this feature, set the  `presets.kubernetesEvents.enabled` property to `true`.
Here is an example `values.yaml`:

```yaml
mode: deployment
replicaCount: 1
presets:
  kubernetesEvents:
    enabled: true
```

### Configuration for Host Metrics

The collector can be configured to collect host metrics for Kubernetes nodes.

This feature is disabled by default. It has the following requirements:

- It requires [Host Metrics receiver](https://opentelemetry.io/docs/kubernetes/collector/components/#host-metrics-receiver) to be included in the collector, such as [contrib](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-contrib) version of the collector image.

To enable this feature, set the  `presets.hostMetrics.enabled` property to `true`.
Here is an example `values.yaml`:

```yaml
mode: daemonset
presets:
  hostMetrics:
    enabled: true
```

## CRDs

At this time, Prometheus CRDs are supported but other CRDs are not.

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.

For more examples see [Examples](examples).
