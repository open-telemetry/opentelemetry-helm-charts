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

#### `presets.prometheus.*` vs. kube-prometheus-stack ServiceMonitors

The `presets.prometheus.*` family (`nodeExporter`, `cadvisor`, `podAnnotations`) adds named instances of the prometheus receiver to the daemonset collector's metrics pipeline. They are a DaemonSet-local alternative to the kube-prometheus-stack (KPS) `ServiceMonitor`-based approach and a **replacement** for the `daemon_scrape_configs.yaml` scrape file. The two approaches produce **similar but not identical** time series.

##### Constraints (chart-enforced)

The presets are gated by template-render assertions; chart rendering fails if these are violated:

* **Mutually exclusive with `scrape_configs_file`**. The presets replace the scrape file (which by default already has node-exporter, kubelet/cAdvisor, and pod-annotation jobs). Enabling any preset while `scrape_configs_file` is non-empty fails with a clear error. Set `scrape_configs_file: ""` to migrate.
* **Require `mode: daemonset`**. The scrape configs reference `${OTEL_K8S_NODE_IP}` / `${OTEL_K8S_NODE_NAME}`, which the OpenTelemetry Operator only injects on daemonset collector pods.

##### Discovery model

|                  | kube-prometheus-stack                                              | `presets.prometheus.*`                                                                                           |
|------------------|--------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------|
| Mechanism        | `ServiceMonitor` CRD → Prometheus Operator generates scrape config | Inline Prometheus scrape config inside each daemonset collector                                                  |
| Discovery        | Kubernetes Endpoints / Pod service discovery                       | `static_configs` (nodeExporter, cadvisor) or `kubernetes_sd_configs` filtered to the local node (podAnnotations) |
| Who scrapes whom | One central Prometheus scrapes every target cluster-wide           | Each daemonset collector scrapes only its own node — sharded by design, no central bottleneck                    |

##### Label set

The exact labels attached vary per preset; the table below shows what each `presets.prometheus.*` emits today versus a KPS ServiceMonitor on the equivalent target.

| Label                          | KPS ServiceMonitor                                               | `nodeExporter`                | `cadvisor`                                     | `podAnnotations`                                            |
|--------------------------------|------------------------------------------------------------------|-------------------------------|------------------------------------------------|-------------------------------------------------------------|
| `job`                          | From `ServiceMonitor.jobLabel` (e.g. `node-exporter`, `kubelet`) | `node-exporter`               | `kubelet`                                      | `kubernetes-pods`, overridable per pod via the `__meta_kubernetes_pod_label_app_kubernetes_io_name` label |
| `instance`                     | `<pod_ip>:<port>` from Endpoints SD                              | `<node_ip>:<port>`            | `<node_ip>:<port>`                             | `<pod_ip>:<port>` from pod SD                               |
| `node`                         | `<node_name>` from `__meta_kubernetes_pod_node_name`             | from `${OTEL_K8S_NODE_NAME}`  | from `${OTEL_K8S_NODE_NAME}`                   | from `__meta_kubernetes_pod_node_name`                      |
| `namespace`                    | from Endpoints SD                                                | —                             | intrinsic (emitted by cAdvisor)                | from `__meta_kubernetes_namespace`                          |
| `pod`                          | from Endpoints SD                                                | —                             | intrinsic                                      | from `__meta_kubernetes_pod_name`                           |
| `container`, `image`           | `container` from Endpoints SD                                    | —                             | intrinsic (`container`, `image` from cAdvisor) | —                                                           |
| Pod labels (`labelmap`)        | via `ServiceMonitor.podTargetLabels`                             | —                             | —                                              | all pod labels mapped via `__meta_kubernetes_pod_label_*`   |
| `service`, `endpoint`          | from Endpoints SD                                                | —                             | —                                              | —                                                           |

For OTel-aware backends, any missing Kubernetes context is supplied downstream by the `k8sattributes` processor (`presets.kubernetesAttributes.enabled`) as resource attributes rather than Prometheus labels.

###### Why `nodeExporter` emits fewer labels

node-exporter metrics are **host-scoped** — `node_cpu_seconds_total` describes the kernel of the underlying node, not any specific pod. When kube-prometheus-stack scrapes node-exporter via Endpoints SD, it attaches `namespace`/`pod`/`container` labels that describe the *exporter's own deployment* (`monitoring/prometheus-node-exporter-xyz/node-exporter`). Those labels carry no information about the metric and are easy to misuse (e.g. `sum by (namespace) (node_cpu_seconds_total)` returns one number for whichever namespace node-exporter is deployed in, not per-workload usage).

The `nodeExporter` preset drops them deliberately; this is a feature, not a parity gap. `cadvisor` and `podAnnotations` series, by contrast, *are* per-workload and so emit `namespace`/`pod`/`container` meaningfully.

##### Backward compatibility with `daemon_scrape_configs.yaml`

Each preset replaces a specific scrape job in `daemon_scrape_configs.yaml`. All three are drop-in compatible — `job` / `instance` / Kubernetes label set are preserved, so existing queries, dashboards, alerts, and recording rules keep working. The remaining differences are either additive (a new `node` label) or default-value tweaks called out per preset below.

###### `nodeExporter` ↔ `node-exporter` job

**Drop-in compatible.** Same scrape target (`${OTEL_K8S_NODE_IP}:9100`), same `job=node-exporter` label, same `scrape_interval: 30s`. The preset additionally emits a `node` label (the legacy job didn't) — purely additive, won't break queries.

###### `cadvisor` ↔ `kubelet` job

**Drop-in compatible.** The preset uses `job_name: kubelet` for label parity with both `daemon_scrape_configs.yaml` (which force-relabels every series to `job=kubelet`) and kube-prometheus-stack (which derives `job=kubelet` from the kubelet Service's `k8s-app` label). Queries / dashboards / alerts filtering `{job="kubelet"}` keep working unchanged.

Minor differences (all additive — no broken queries):

* **Scrape interval**: the preset defaults to `30s`, the legacy job uses `15s`. Set `presets.prometheus.cadvisor.scrapeInterval: 15s` to match exactly (affects `rate()` resolution).
* **Dropped helper labels**: the legacy job attaches `endpoint=https-metrics` and `metrics_path=/metrics/cadvisor`; the preset does not. Rarely referenced in queries.
* **Intrinsic cAdvisor labels** (`namespace`, `pod`, `container`, `image`, `id`, ...) are identical in both — these come from cAdvisor itself, not from relabel rules.
* **`metric_relabel_configs`**: identical drop list (container_cpu_load_average_10s, container_spec_*, container_fs_io_current, container_memory_mapped_file/swap, container_file_descriptors/tasks_state/threads_max, plus non-pod cgroup rows).

###### `podAnnotations` ↔ `kubernetes-pods` job

**Drop-in compatible.** Same `job_name: kubernetes-pods` (overridable per pod via the `app.kubernetes.io/name` pod label, in both cases), same label set (`namespace`, `pod`, all pod labels via `labelmap`), same `scrape_interval: 30s`, same annotation-driven scheme/path/port/param handling.

Differences from the legacy job (both additive — no broken queries):

* **`node` label** added by the preset (sourced from `__meta_kubernetes_pod_node_name`).
* **Self-scrape filter**: the preset's pod selector excludes pods with `app.kubernetes.io/component=opentelemetry-collector` to prevent the collector from scraping itself. The legacy job has no such filter, so it would scrape any collector pod carrying `prometheus.io/scrape: "true"`.

##### Customization

KPS exposes `relabelings` and `metricRelabelings` on each `ServiceMonitor`. The presets expose `enabled`, `scrapeInterval`, `scrapeTimeout`, and — for `nodeExporter` / `cadvisor` only — `port`. (`podAnnotations` discovers the port per pod from the `prometheus.io/port` annotation, so a chart-level `port` knob doesn't apply.) For richer relabeling, drop the preset and use `scrape_configs_file` instead — see [scrape_configs_file Details](#scrape_configs_file-details).

##### Other duplicate-scrape risks

* **`prometheus-node-exporter` subchart**: when installed via the top-level `nodeExporter.enabled: true` flag, the subchart creates its own `ServiceMonitor` by default. If a target allocator picks it up, node-exporter is scraped twice — once locally by every daemonset collector and once via the ServiceMonitor through the cluster collector.

##### When to use which

* **Use the presets** if you want a sharded, DaemonSet-native pipeline with no central Prometheus bottleneck and your dashboards rely primarily on `job` / `instance` / `node` (and, for `podAnnotations`, the standard Kubernetes label set).
* **Use the target allocator + ServiceMonitors** (set `targetAllocator.enabled: true` instead) if you need full KPS label parity (including `service` / `endpoint` / `container`), want CRD-driven dynamic configuration, or are porting existing KPS dashboards/recording rules unchanged.

### Image versioning

The appVersion of the chart is aligned to the latest image version of the operator. Images are upgraded within the chart manually by setting the image tag to the latest release of each image used. This will be the latest patch release for the chart's appVersion. example:
```
appVersion: 0.103.0
collector.image.tag: 0.103.1
bridge.image.tag: 0.103.0
```

### scrape_configs_file Details

> [!NOTE]
> This parameter only works when running the helm chart locally. When installing the helm chart using the remote repository it is not possible to include "external" scrape config files into the helm structure. This is also true when the chart is used as a subchart, and the scrape config files exists in the parent chart. Ref. [helm docs](https://helm.sh/docs/chart_template_guide/accessing_files/)

By default, the daemonset collector will load in the daemon_scrape_configs.yaml file which collects prometheus metrics from applications on the same node that have the prometheus.io/scrape=true annotation, kubernetes node metrics, and cadvisor metrics. Users can disable this by settings collectors.daemon.scrape_configs_file: "" OR they can provide their own promethues scrape config file for the daemonset by supplying collectors.daemon.scrape_configs_file: "<your-file>.yaml"

## Prerequisites

- Kubernetes 1.24+ is required for OpenTelemetry Operator installation
- Helm 3.9+

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
