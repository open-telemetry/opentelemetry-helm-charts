# OpenTelemetry Demo Helm Chart

The helm chart installs [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo)
in kubernetes cluster and sends data to Datadog Backend

## Prerequisites

- Helm 3.0+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-otel-demo, run the following command:

We can install open telemetry collector either as gateway or daemonset. Please create API key from datadog .

```console
helm install my-otel-demo open-telemetry/opentelemetry-demo-datadog --set apiKey=XXX --set deployMode='daemonset'
```
