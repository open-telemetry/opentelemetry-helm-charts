# Examples of chart configuration

Here is a collection of common configurations for the OpenTelemetry Kube Stack chart. Each folder contains an example `values.yaml`.

The manifests can be rendered using the `helm template` command and the specific example folder's values.yaml.

Example: 

```sh
helm template default-example open-telemetry/opentelemetry-kube-stack --values ./charts/opentelemetry-kube-stack/examples/default
```

Additionally, all the examples can be generated with

```sh
make generate-examples CHARTS=opentelemetry-collector
```
