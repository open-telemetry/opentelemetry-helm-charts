# Collector Fleet example

This example shows a complete deployment of the Helm chart in conjunction with a set of collectors and Prometheus targets exposed via prometheus.io annotations using the consistent-hashing approach.

The goal is to show a complete setup involving collectors, Prometheus scrape endpoints and the Target Allocator.

# Prerequisites

You will need a computer with Docker installed, [kind (Kubernetes in Docker)](https://kind.sigs.k8s.io/) and optionally [Helm](https://helm.sh/).

# Set up

## Kind cluster
Create a kind cluster with:
```shell
kind create cluster
```

## Deploy the helm chart

From the root of the checkout of this repository:
```shell
helm upgrade --install ta charts/opentelemetry-target-allocator --values charts/opentelemetry-target-allocator/examples/collector-fleet/values.yaml
```

You can also apply the rendered manifests:

```shell
kubectl apply -f ./charts/opentelemetry-target-allocator/examples/collector-fleet/rendered
```

## Deploy Prometheus targets

```shell
kubectl apply -f ./charts/opentelemetry-target-allocator/examples/collector-fleet/prometheus_example_pods.yaml
```

## Deploy collectors

```shell
kubectl apply -f ./charts/opentelemetry-target-allocator/examples/collector-fleet/collectors.yaml
```

# Investigate and check the outputs

## Check the target allocator scrape configs

Expose the target allocator service to your host with:
```shell
kubectl port-forward service/ta-opentelemetry-target-allocator-ta 8080:80
```

You can then visit `http://localhost:8080/jobs/prom/targets` on your web browser to see the discovered targets.

Example:
```json
{
  "example-opentelemetry-collector-57fdb66b6-4np86": {
    "_link": "/jobs/prom/targets?collector_id=example-opentelemetry-collector-57fdb66b6-4np86",
    "targets": [
      {
        "targets": [
          "10.244.0.22:8080"
        ],
        "labels": {
          "__address__": "10.244.0.22:8080",
          "__meta_kubernetes_namespace": "default",
          "__meta_kubernetes_pod_annotation_prometheus_io_path": "/metrics",
          "__meta_kubernetes_pod_annotation_prometheus_io_port": "8080",
          "__meta_kubernetes_pod_annotation_prometheus_io_scrape": "true",
          "__meta_kubernetes_pod_annotationpresent_prometheus_io_path": "true",
          "__meta_kubernetes_pod_annotationpresent_prometheus_io_port": "true",
          "__meta_kubernetes_pod_annotationpresent_prometheus_io_scrape": "true",
          "__meta_kubernetes_pod_container_id": "containerd://ecd848db8f93545de3ca0dc79d84b876a6babff166495c41db76a48216ee9ec4",
          "__meta_kubernetes_pod_container_image": "quay.io/brancz/prometheus-example-app:v0.3.0",
          "__meta_kubernetes_pod_container_init": "false",
          "__meta_kubernetes_pod_container_name": "prom",
          "__meta_kubernetes_pod_container_port_name": "http-port",
          "__meta_kubernetes_pod_container_port_number": "8080",
          "__meta_kubernetes_pod_container_port_protocol": "TCP",
          "__meta_kubernetes_pod_controller_kind": "ReplicaSet",
          "__meta_kubernetes_pod_controller_name": "prometheus-1-85bfd98dc6",
          "__meta_kubernetes_pod_host_ip": "172.18.0.2",
          "__meta_kubernetes_pod_ip": "10.244.0.22",
          "__meta_kubernetes_pod_label_app": "prom",
          "__meta_kubernetes_pod_label_pod_template_hash": "85bfd98dc6",
          "__meta_kubernetes_pod_labelpresent_app": "true",
          "__meta_kubernetes_pod_labelpresent_pod_template_hash": "true",
          "__meta_kubernetes_pod_name": "prometheus-1-85bfd98dc6-gnq54",
          "__meta_kubernetes_pod_node_name": "kind-control-plane",
          "__meta_kubernetes_pod_phase": "Running",
          "__meta_kubernetes_pod_ready": "true",
          "__meta_kubernetes_pod_uid": "c746569e-34ee-4e6e-b80a-e5bd31b3f39f"
        }
      },
<snip>
```

You can even visit individual links to see each collector's allocation.

## Check out the collector outputs.

Find a collector pod, get its logs:

```shell
kubectl logs $(kubectl get pods | grep collector | awk '{print $1}' | head -n 1)
```

You will see the collector logs metrics using the debug exporter.
