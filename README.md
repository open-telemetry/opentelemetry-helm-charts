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
[OpenTelemetry Collector chart directory](./charts/opentelemetry-collector).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

Approvers ([@open-telemetry/helm-approvers](https://github.com/orgs/open-telemetry/teams/helm-approvers)):

- [Alex Birca](https://github.com/Allex1), Adobe

Emeritus Approvers:

- [Naseem K. Ullah](https://github.com/naseemkullah), Transit

Maintainers ([@open-telemetry/helm-maintainers](https://github.com/orgs/open-telemetry/teams/helm-maintainers)):

- [Dmitrii Anoshin](https://github.com/dmitryax), Splunk
- [Tyler Helmuth](https://github.com/TylerHelmuth), New Relic

Emeritus Maintainers:

- [Tigran Najaryan](https://github.com/tigrannajaryan), Splunk

Learn more about roles in the [community repository](https://github.com/open-telemetry/community/blob/main/community-membership.md).

## License

[Apache 2.0 License](./LICENSE).
