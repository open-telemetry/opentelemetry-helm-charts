# OpenTelemetry Demo Helm Chart

The helm chart installs [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo)
in kubernetes cluster and sends traces and logs to a VMware Aria Operations for Applications tenant

## Prerequisites

- Helm 3.0+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```
Download this chart from: https://github.com/dambott/opentelemetry-helm-charts

Edit the values.yaml to add your Aria Applications token and url and set the k8s cluster name on line 55

Also edit templates/40_fluent-configmap.yaml line 142 to set the cluster_name to the same k8s cluster name

To install the chart with the release name my-otel-demo, run the following command:

```console
cd charts/opentelemetry-demo
kubectl create namespace my-otel-demo
helm install --namespace my-otel-demo my-otel-demo .
```
