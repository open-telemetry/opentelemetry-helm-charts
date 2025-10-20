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

By default the chart configures endpoints for IPv4 addresses. When deploying in an IPv6 environment set `networkMode: ipv6` so the endpoints use bracket notation around IP variables.

## Configuration

### Default configuration

By default this chart will deploy an OpenTelemetry Collector with three pipelines (logs, metrics and traces)
and debug exporter enabled by default. The collector can be installed either as daemonset (agent), deployment or stateful set.

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

### Configuration for Resource Detection

The resource detection preset can add infrastructure metadata such as the host ID and cloud provider attributes to your telemetry. To enable it, set `presets.resourceDetection.enabled` to `true`.

You can control which detectors are enabled by configuring the `presets.resourceDetection.detectors` block. The `env` list defaults to the chart's built-in environment detectors, while the optional `cloud` list lets you restrict cloud detectors to the platforms you run on. When `cloud` is omitted or left empty, the chart falls back to its default detector list for the selected distribution. The example below demonstrates narrowing the environment detectors to only the `env` detector and limiting cloud detection to GCP and Azure.

Here is an example `values.yaml`:

```yaml
presets:
  resourceDetection:
    enabled: true
    detectors:
      env:
        - env
      cloud:
        - gcp
        - azure
```

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

The container logs pipeline uses the `debug` exporter by default.
Paired with the default `filelog` receiver that receives all containers' console output,
it is easy to accidentally feed the exported logs back into the receiver.

Also note that using the `--verbosity=detailed` option for the `debug` exporter causes it to output
multiple lines per single received log, which when looped, would amplify the logs exponentially.

To prevent the looping, the default configuration of the receiver excludes logs from the collector's containers.

If you want to include the collector's logs, make sure to replace the `debug` exporter
with an exporter that does not send logs to collector's standard output.

Here's an example `values.yaml` file that replaces the default `debug` exporter on the `logs` pipeline
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

### Configuration for Journald Logs

The collector can read logs directly from the systemd journal by enabling the
`journaldReceiver` preset. When enabled, the chart mounts the host's journal
directory (default `/run/log/journal`) into the collector pod and adds the
`journald` receiver to the logs pipeline.

This feature is disabled by default and requires Linux nodes with access to the
systemd journal. For clusters where hostPath volumes are restricted (such as
managed serverless offerings), ensure the required permissions are granted
before enabling the preset.

Optional fields allow further filtering:

- `directory`: Override the journal directory to mount and read from.
- `units`: Limit collection to specific systemd units.
- `matches`: Provide additional journald matchers for fine-grained selection.

Here is an example `values.yaml`:

```yaml
mode: daemonset

presets:
  journaldReceiver:
    enabled: true
    directory: /run/log/journal
    units:
      - ssh
      - kubelet
      - docker
    matches:
      - _SYSTEMD_UNIT: kubelet.service
      - _SYSTEMD_UNIT: ssh.service
        _UID: "1000"
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
    podUid:
      enabled: true
    podStartTime:
      enabled: true
    # When enabled adds a node_from_env_var filter and sets the K8S_NODE_NAME
    # environment variable automatically when required.
    nodeFilter:
      enabled: true
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
    # Optional custom metrics for Kubernetes dashboard compatibility
    customMetrics:
      enabled: true
    # collectionInterval: 30s
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
    # Optional cluster name attribute for events
    clusterName: "production"
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

### Configuration for ZPages

The collector can expose [zPages](https://opentelemetry.io/docs/collector/monitoring/) for debugging.

This feature is disabled by default.

To enable this feature, set the `presets.zpages.enabled` property to `true`.
Here is an example `values.yaml`:

```yaml
presets:
  zpages:
    enabled: true
```

The HTTP endpoint can be configured via `presets.zpages.endpoint`.

### Configuration for Pprof

The collector can expose [pprof](https://github.com/google/pprof) for profiling.

This feature is disabled by default.

To enable this feature, set the `presets.pprof.enabled` property to `true`.
Here is an example `values.yaml`:

```yaml
presets:
  pprof:
    enabled: true
```

The HTTP endpoint can be configured via `presets.pprof.endpoint`.

### Configuration for standalone distribution

The standalone distribution is intended for Linux hosts where the collector runs without
an orchestrator-provided pod IP or `/hostfs` mount. Set the `distribution` value to
`"standalone"` to enable the following behaviours:

- Prometheus receivers bind to `0.0.0.0` instead of a pod IP so that they accept
  connections on any interface.
- Host metrics scrape the real root filesystem at `/` rather than the Kubernetes
  `/hostfs` mount.

Here is an example `values.yaml`:

```yaml
distribution: "standalone"
```

### Configuration for GKE autopilot distribution

GKE Autopilot has limited access to host filesystems and host ports, due to this some features of OpenTelemetry Collector doesn't work.
More information about limitations is available in [GKE Autopilot security capabilities document](https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-security)

To deploy into GKE Autopilot you need to configuration "gke/autopilot" distribution.
Here is an example `values.yaml`:
```yaml
distribution: "gke/autopilot"
```

This setting will:
- disable `/var/lib/docker` mount
- disable allocating host ports.

Note due to limited access, these options will not work:
- `presets.hostMetrics`
- `presets.logsCollection.storeCheckpoints`

## CRDs

At this time, Prometheus CRDs are supported but other CRDs are not.

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.

For more examples see [Examples](examples).
