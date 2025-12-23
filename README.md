# OpenTelemetry Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/opentelemetry-helm)](https://artifacthub.io/packages/search?repo=opentelemetry-helm)

This repository contains [Helm](https://helm.sh/) charts for OpenTelemetry project.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

Once Helm is set up properly, add the repo as follows:

```console
$ helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

## Helm Charts

You can then run `helm search repo open-telemetry` to see the charts.

### OpenTelemetry Collector

The chart can be used to install [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry Collector chart directory](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-collector).

### OpenTelemetry Demo

The chart can be used to install [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry Demo chart directory](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-demo).

### OpenTelemetry Operator

The chart can be used to install [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry Operator chart directory](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator).

### OpenTelemetry eBPF Instrumentation

The chart can be used to install [OpenTelemetry eBPF Instrumentation](https://github.com/open-telemetry/opentelemetry-ebpf-instrumentation)
in a Kubernetes cluster. More detailed documentation can be found in
[OpenTelemetry eBPF Instrumentation chart directory](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-ebpf-instrumentation).

## Contributing

See [CONTRIBUTING.md](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/CONTRIBUTING.md).

### Maintainers

- [Dmitrii Anoshin](https://github.com/dmitryax), Splunk
- [Jacob Aronoff](https://github.com/jaronoff97), Lightstep
- [Tyler Helmuth](https://github.com/TylerHelmuth), Honeycomb

For more information about the maintainer role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#maintainer).

### Approvers

- [Alex Birca](https://github.com/Allex1), Adobe
- [Jared Tan](https://github.com/JaredTan95), DaoCloud
- [Josh Voravong](https://github.com/jvoravong), Splunk
- [Juliano Costa](https://github.com/julianocosta89), Datadog
- [Pierre Tessier](https://github.com/puckpuck), Honeycomb
- [Povilas](https://github.com/povilasv), Coralogix

For more information about the approver role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#approver).

### Emeritus Maintainers

- [Tigran Najaryan](https://github.com/tigrannajaryan)

For more information about the emeritus role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#emeritus-maintainerapprovertriager).

### Emeritus Approvers

- [Naseem K. Ullah](https://github.com/naseemkullah)

For more information about the emeritus role, see the [community repository](https://github.com/open-telemetry/community/blob/main/guides/contributor/membership.md#emeritus-maintainerapprovertriager).

## License

[Apache 2.0 License](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/LICENSE).
