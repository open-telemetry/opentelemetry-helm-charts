# OpenTelemetry Auto Instrumentation Helm Chart

The helm chart installs the [OpenTelemetry Operator Auto Instrumentation Webhook](https://github.com/open-telemetry/opentelemetry-operator/tree/main/)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-auto-instrumentation, run the following command:

```console
helm install my-auto-instrumentation open-telemetry/opentelemetry-auto-instrumentation
```

## Upgrading

See [UPGRADING.md](UPGRADING.md).

## Configuration

### Default configuration

By default this chart will deploy a pod mutating webhook to mutate new pods with auto-instrumentation init containers that will add the instrumentation SDKs to pods.

Pods can be annotated with `instrumentation.opentelemetry.io/inject-java: "true"`, `instrumentation.opentelemetry.io/inject-nodejs: "true"` and more.
See https://github.com/open-telemetry/opentelemetry-operator for the complex list of supported options.

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.

For more examples see [Examples](examples).
