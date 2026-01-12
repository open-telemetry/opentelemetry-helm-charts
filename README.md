# OpenTelemetry Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This repository is a fork of [opentelemetry/opentelemetry-helm-charts](https://github.com/open-telemetry/opentelemetry-helm-charts) and contains [Helm](https://helm.sh/) charts for OpenTelemetry project, customized for Liteverge.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
helm repo add liteverge-opentelemetry https://liteverge.github.io/opentelemetry-helm-charts
```

## Helm Charts

You can then run `helm search repo liteverge-opentelemetry` to see the charts.

### OpenTelemetry Collector

The chart can be used to install [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry Collector chart directory](https://github.com/liteverge/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector).

### OpenTelemetry Demo

The chart can be used to install [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry Demo chart directory](https://github.com/liteverge/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo).

### OpenTelemetry Operator

The chart can be used to install [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry Operator chart directory](https://github.com/liteverge/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator).

### OpenTelemetry eBPF Instrumentation

The chart can be used to install [OpenTelemetry eBPF Instrumentation](https://github.com/open-telemetry/opentelemetry-ebpf-instrumentation)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry eBPF Instrumentation chart directory](https://github.com/liteverge/opentelemetry-helm-charts/tree/main/charts/opentelemetry-ebpf-instrumentation).

## Contributing

See [CONTRIBUTING.md](https://github.com/liteverge/opentelemetry-helm-charts/tree/main/CONTRIBUTING.md).

## Upstream Repository

This is a fork of the official OpenTelemetry Helm Charts repository. For information about the upstream maintainers and approvers, see the [upstream repository](https://github.com/open-telemetry/opentelemetry-helm-charts).

## License

[Apache 2.0 License](https://github.com/liteverge/opentelemetry-helm-charts/tree/main/LICENSE).
