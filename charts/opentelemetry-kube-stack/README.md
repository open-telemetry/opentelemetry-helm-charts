# OpenTelemetry Kube Stack Helm Chart

| Status        |           |
| ------------- |-----------|
| Stability     | [alpha]   |
| Issues        | [![Open issues](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-helm-charts?query=is%3Aissue+is%3Aopen+label%3Achart%3Akube-stack&label=open&color=orange&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-helm-charts/issues?q=is%3Aissue+is%3Aopen+label%3Achart%3Akube-stack) [![Closed issues](https://img.shields.io/github/issues-search/open-telemetry/opentelemetry-helm-charts?query=is%3Aissue%20is%3Aclosed%20label%3Achart%3Akube-stack%20&label=closed&color=blue&logo=opentelemetry)](https://github.com/open-telemetry/opentelemetry-helm-charts/issues?q=is%3Aclosed+is%3Aissue+label%3Achart%3Akube-stack) |
| [Code Owners](https://github.com/open-telemetry/opentelemetry-helm-charts/blob/main/CONTRIBUTING.md)    | [@jaronoff97](https://www.github.com/jaronoff97), [@TylerHelmuth](https://github.com/TylerHelmuth), [@dmitryax](https://github.com/dmitryax) |


This Helm chart serves as a quickstart for OpenTelemetry in a Kubernetes environment. The chart installs an [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) and a suite of collectors that help you get started with OpenTelemetry metrics, traces, and logs.

## Features

This chart installs the OpenTelemetry Operator and a daemonset collector pool with the following features:
* Kubernetes infrastructure metrics
* Applications logs
* OTLP trace receiver
* Kubernetes resource enrichment
* Kubernetes events
* Cluster metrics

**Note**: This setup requires the usage of leader election extension, if this isn't posible for any reason, this extension can be avoided with [this alternative setup](/charts/opentelemetry-kube-stack/examples/no-leader-election-extension/README.md)

## Usage

For example usage of this chart, please look in the examples/ folder where you can see how you can set a custom OTLP exporter for your desired destination. The example configuration also shows how to enable Instrumentation and OpAMP Bridge resources.

### Kube-Prometheus-Stack compatability
This chart provides functionality to port an existing scrape configuration from the [kube-prometheus-stack chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) to this chart. This is accomplished by embedding the [kube-state-metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics) and [prometheus-node-exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter) charts. Each of the versions installed in this chart is pinned the latest minor version in the published repositories.

> [!NOTE]
> More work is needed for full compatibility. Specifically, the exporter configuration provided for various kubernetes infrastructure components.

> [!NOTE]
> This chart aims to provide compatibility for scrape targets from the kube-prometheus-stack chart. This chart is not responsible for applying Prometheus Rules, Alertmanager, or a Prometheus instance.

#### `presets.prometheus.*` presets

The `presets.prometheus.*` family (`nodeExporter`, `cadvisor`, `podAnnotations`) configure the OpenTelemetry Collectors to scrape popular Prometheus Kubernetes metrics:

* `presets.prometheus.nodeExporter`: Kubernetes node metrics exposed with the [prometheus-node-exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter),
* `presets.prometheus.cadvisor`: [cAdvisor](https://github.com/google/cadvisor) metrics scraped from the kubelet,
* `presets.prometheus.podAnnotations`: custom pod metrics exposed using the `prometheus.io/scrape=true` Kubernetes annotation.

The `prometheus.*` presets are implemented adding named instances of the [Prometheus receiver](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/prometheusreceiver) to the daemonset collector's metrics pipeline (`prometheus/node_exporter`, `prometheus/cadvisor`, and `prometheus/pod_annotations`).
They are a **replacement** for the `daemon_scrape_configs.yaml` scrape file.

<details>
<summary>Constraints (chart-enforced)</summary>

The `prometheus.*` presets are gated; chart rendering fails if these are violated:

* **Mutually exclusive with `scrape_configs_file`**. The presets replace the scrape file (which by default already has node-exporter, kubelet/cAdvisor, and pod-annotation jobs). Enabling any preset while `scrape_configs_file` is non-empty fails with a clear error. Set `scrape_configs_file: ""` to migrate.
* **Require `mode: daemonset`**. The scrape configs reference `${OTEL_K8S_NODE_IP}` / `${OTEL_K8S_NODE_NAME}`, which the OpenTelemetry Operator only injects on daemonset collector pods.

</details>

#### Prometheus metrics label set

The `presets.prometheus.*` presets produce the same Prometheus labels as the Kube-Prometheus-Stack.

<details>
<summary>Details</summary>

The exact labels attached vary per preset:

| Prometheus label        | `nodeExporter`               | `cadvisor`                                     | `podAnnotations`                                            |
|-------------------------|------------------------------|------------------------------------------------|-------------------------------------------------------------|
| `job`                   | `node-exporter`              | `kubelet`                                      | `kubernetes-pods`, overridable per pod via the `app.kubernetes.io/name` pod label |
| `instance`              | `<node_ip>:<port>`           | `<node_ip>:<port>`                             | `<pod_ip>:<port>` from pod SD                               |
| `node`                  | from `${OTEL_K8S_NODE_NAME}` | from `${OTEL_K8S_NODE_NAME}`                   | from `__meta_kubernetes_pod_node_name`                      |
| `namespace`             | —                            | intrinsic (emitted by cAdvisor)                | from `__meta_kubernetes_namespace`                          |
| `pod`                   | —                            | intrinsic                                      | from `__meta_kubernetes_pod_name`                           |
| `container`, `image`    | —                            | intrinsic (`container`, `image` from cAdvisor) | —                                                           |
| Pod labels (`labelmap`) | —                            | —                                              | all pod labels mapped via `__meta_kubernetes_pod_label_*`   |

Prometheus labels are mapped to OpenTelemetry metrics data points and resource attributes according to the `prometheus` receiver [Resource Attribute Mapping](https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/receiver/prometheusreceiver/resource_attribute_mapping.md)

Kubernetes resource attributes (`k8s.*`) are eventually supplied downstream by the `k8s_attributes` processor when `presets.kubernetesAttributes.enabled=true` (recommended).

</details>

##### Differences between `presets.prometheus.*` and `daemon_scrape_configs.yaml` metrics

`presets.prometheus.*` are designed to replace `daemon_scrape_configs.yaml`, with each preset mapping to a specific scrape job in that file. All three presets retain the same labels — `job`, `instance`, and Kubernetes labels. Notable differences include additional labels (e.g. `node`) and default-value adjustments for improved consistency, as described per preset below.

<details>
<summary>Details</summary>

###### `presets.prometheus.nodeExporter` ↔ `daemon_scrape_configs.yaml`'s `node-exporter` job

Same scrape target (`${OTEL_K8S_NODE_IP}:9100`), same `job=node-exporter` label, same `scrape_interval: 30s`. The preset additionally emits a `node` label (the legacy job didn't).

###### `presets.prometheus.cadvisor` ↔ `daemon_scrape_configs.yaml`'s `kubelet` job

Same `job=kubelet` label as `daemon_scrape_configs.yaml` (which force-relabels every series to `job=kubelet`).

Minor differences:

* **Scrape interval**: the preset defaults to `30s`, the `daemon_scrape_configs.yaml` job uses `15s`. Set `presets.prometheus.cadvisor.scrapeInterval: 15s` to match exactly (affects `rate()` resolution).
* **Dropped helper labels**: the `daemon_scrape_configs.yaml` job attaches `endpoint=https-metrics` and `metrics_path=/metrics/cadvisor`; the preset does not.
* **Intrinsic cAdvisor labels** (`namespace`, `pod`, `container`, `image`, `id`, ...) are identical in both — these come from cAdvisor itself, not from relabel rules.
* **`metric_relabel_configs`**: identical drop list (`container_cpu_load_average_10s`, `container_spec_*`, `container_fs_io_current`, `container_memory_mapped_file/swap`, `container_file_descriptors/tasks_state/threads_max`, plus non-pod cgroup rows).

###### `presets.prometheus.podAnnotations` ↔ `daemon_scrape_configs.yaml`'s `kubernetes-pods` job

Same `job=kubernetes-pods` (overridable per pod via the `app.kubernetes.io/name` pod label, in both cases), same label set (`namespace`, `pod`, all pod labels via `labelmap`), same `scrape_interval: 30s`, same annotation-driven scheme/path/port/param handling.

Differences from the `daemon_scrape_configs.yaml` job:

* **`node` label** added by the preset (sourced from `__meta_kubernetes_pod_node_name`).
* **Self-scrape filter**: the preset's pod selector excludes pods with `app.kubernetes.io/component=opentelemetry-collector` to prevent the collector from scraping itself. The `daemon_scrape_configs.yaml` job has no such filter, so it would scrape any collector pod carrying `prometheus.io/scrape: "true"`.

</details>

#### `scrape_configs_file=daemon_scrape_configs.yaml`

> [!NOTE]
> This parameter only works when running the helm chart locally. When installing the helm chart using the remote repository it is not possible to include "external" scrape config files into the helm structure. This is also true when the chart is used as a subchart, and the scrape config files exists in the parent chart. Ref. [helm docs](https://helm.sh/docs/chart_template_guide/accessing_files/)

By default, the daemonset collector will load in the daemon_scrape_configs.yaml file which collects Prometheus metrics from applications on the same node that have the `prometheus.io/scrape=true` annotation, kubernetes node metrics, and cadvisor metrics. Users can disable this by settings collectors.daemon.scrape_configs_file: "" OR they can provide their own promethues scrape config file for the daemonset by supplying collectors.daemon.scrape_configs_file: "<your-file>.yaml"

#### Duplicate-scrape risks

**`prometheus-node-exporter` subchart**: when installed via the top-level `nodeExporter.enabled: true` flag, the subchart creates its own `ServiceMonitor` by default.
If a target allocator picks it up and `presets.prometheus.nodeExporter.enabled=true` or `scrape_configs_file=daemon_scrape_configs.yaml`, then node-exporter metrics are scraped twice.

### Image versioning

The appVersion of the chart is aligned to the latest image version of the operator. Images are upgraded within the chart manually by setting the image tag to the latest release of each image used. This will be the latest patch release for the chart's appVersion. example:
```
appVersion: 0.103.0
collector.image.tag: 0.103.1
bridge.image.tag: 0.103.0
```


## Prerequisites

- Kubernetes 1.24+ is required for OpenTelemetry Operator installation
- Helm 4.0+

### TLS Certificate Requirement

<details>
<summary>Cert Manager Dependendency</summary>
<br>
In Kubernetes, in order for the API server to communicate with the webhook component, the webhook requires a TLS
certificate that the API server is configured to trust. There are a few different ways you can use to generate/configure the required TLS certificate.

- The easiest and default method is to install the [cert-manager](https://cert-manager.io/docs/) and set `opentelemetry-operator.admissionWebhooks.certManager.enabled` to `true`.
  In this way, cert-manager will generate a self-signed certificate. _See [cert-manager installation](https://cert-manager.io/docs/installation/kubernetes/) for more details._
- You can provide your own Issuer by configuring the `opentelemetry-operator.admissionWebhooks.certManager.issuerRef` value. You will need
  to specify the `kind` (Issuer or ClusterIssuer) and the `name`. Note that this method also requires the installation of cert-manager.
- You can use an automatically generated self-signed certificate by setting `opentelemetry-operator.admissionWebhooks.certManager.enabled` to `false` and `opentelemetry-operator.admissionWebhooks.autoGenerateCert.enabled` to `true`. Helm will create a self-signed cert and a secret for you.
- You can use your own generated self-signed certificate by setting both `opentelemetry-operator.admissionWebhooks.certManager.enabled` and `opentelemetry-operator.admissionWebhooks.autoGenerateCert.enabled` to `false`. You should provide the necessary values to `opentelemetry-operator.admissionWebhooks.cert_file`, `opentelemetry-operator.admissionWebhooks.key_file`, and `opentelemetry-operator.admissionWebhooks.ca_file`.
- You can sideload custom webhooks and certificate by disabling `.Values.opentelemetry-operator.admissionWebhooks.create` and `opentelemetry-operator.admissionWebhooks.certManager.enabled` while setting your custom cert secret name in `opentelemetry-operator.admissionWebhooks.secretName`
- You can disable webhooks altogether by disabling `.Values.opentelemetry-operator.admissionWebhooks.create` and setting env var to `ENABLE_WEBHOOKS: "false"`
</details>

## Add Repository

```console
$ helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
$ helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Chart

```console
$ helm install \
  opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

If you created a custom namespace, like in the TLS Certificate Requirement section above, you will need to specify the namespace with the `--namespace` helm option:

```console
$ helm install --namespace opentelemetry-operator-system \
  opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

If you wish for helm to create an automatically generated self-signed certificate, make sure to set the appropriate values when installing the chart:

```console
$ helm install  --set opentelemetry-operator.admissionWebhooks.certManager.enabled=false --set admissionWebhooks.autoGenerateCert.enabled=true \
  opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Chart

The following command uninstalls the chart whose release name is opentelemetry-kube-stack.

```console
$ helm uninstall opentelemetry-kube-stack
```

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

This will remove all the Kubernetes components associated with the chart and deletes the release.

The OpenTelemetry Collector CRD created by this chart won't be removed by default and should be manually deleted:

```console
$ kubectl delete crd opentelemetrycollectors.opentelemetry.io
$ kubectl delete crd opampbridges.opentelemetry.io
$ kubectl delete crd instrumentations.opentelemetry.io
```

## Upgrade Chart

```console
$ helm upgrade opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

Please note that by default, the chart will be upgraded to the latest version. If you want to upgrade to a specific version,
use `--version` flag.

With Helm v3.0, CRDs created by this chart are not updated by default and should be manually updated.
Consult also the [Helm Documentation on CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions).

_See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation._

### Upgrade from 0.6.x to 0.7.x

Version 0.7.0 has unified the previous collectors (daemonset and deployment) in a single one. If you are using custom configurations for `cluster` collector, you will need to merge your `cluster` collector configuration with `daemon` collector and remove `collectors.cluster` section from your values file.
If you are using helm, upgrade command is enough the prune old resources, but gitops approaches like 'ArgoCD' could require to select pruning options during sync process to get rid of removed resources.

## Configuration

The following command will show all the configurable options with detailed comments.

```console
$ helm show values open-telemetry/opentelemetry-kube-stack
```

When using this chart as a subchart, you may want to unset certain default values. Since Helm v3.13 values handling is improved and null can now consistently be used to remove values (e.g. to remove the default CPU limits).
