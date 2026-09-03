# Prometheus Replacement example
This example contains files to allow a user to replace an installation of kube-prometheus-stack. The opentelemetry-kube-stack chart aims to make the replacement process straightforward by utilizing the target allocator to pull any servicemonitors and podmonitors.

> [!INFO]
> This chart has most of the same configurations as the kube-prometheus-stack chart, but requires that kubelet monitoring is done via ScrapeConfig custom resources. This is because of how the prometheus-operator manages endpoints for the Kubelet service. If you'd like to avoid scrape configs altogether, it's recommended to use the kubelet receiver in the opentelemetry collector.

## Usage

Install the chart with this example's values file:

```bash
helm install opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack -f values.yaml
```

Then create the kubelet scrape configuration. The manifests assume the `default` namespace, so adjust the namespace fields in the file first if you installed the chart elsewhere:

```bash
kubectl apply -n default -f kubelet_scrape_configs_cr.yaml
```

The chart installs the required ScrapeConfig CRD by default through its prometheus-crds dependency (`crds.installPrometheus`).

## How kubelet scraping works here

`kubelet_scrape_configs_cr.yaml` contains ScrapeConfig custom resources for the kubelet's `/metrics`, `/metrics/cadvisor`, and `/metrics/probes` endpoints, along with a dedicated service account, token secret, and the RBAC needed to authenticate against the kubelet. The target allocator picks these up through the `scrapeConfigSelector` configured in this example's values.yaml and distributes the resulting jobs to the daemonset collector.

Earlier versions of this example pointed `scrape_configs_file` at `examples/prometheus-otel/kubelet_scrape_configs.yaml`. That only works from a checkout of this repository's source tree, because packaged charts (for example those fetched with `helm pull`) do not include the examples folder. The ScrapeConfig approach works the same way regardless of how the chart was obtained. The raw prometheus form of the kubelet scrape configuration is kept in `kubelet_scrape_configs.yaml` as a reference for users who prefer to inline it into their collector configuration.
