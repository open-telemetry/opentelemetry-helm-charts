# OpenTelemetry Helm Charts

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

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

## License

[Apache 2.0 License](./LICENSE).
