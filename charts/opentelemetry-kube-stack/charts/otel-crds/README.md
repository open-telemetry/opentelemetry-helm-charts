# OpenTelemetry Collector CRDs

This chart contains the CRDs for _*installation*_ only right now for the opentelemetry-operator. This allows the OpenTelemetry Kubernetes Stack chart to work on install. You can see more discussion about this [here](https://github.com/open-telemetry/opentelemetry-helm-charts/issues/677) and [here](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/1203).

This approach is inspired by the kube-prometheus-stack approach which you can see discussion on [here](https://github.com/prometheus-community/helm-charts/issues/3548).

> [!NOTE]
> This chart explicitly _does not_ support the conversion webhook that is currently in the opentelemetry-operator chart. This is because the opentelemetry-kube-stack chart will only work with v1beta1 CRDs. This chart is not meant for use with v1alpha1 Collector CRDs.

# Upgrade Notes

Upgrades for otel-crds are handled via the `make update-opentelemetry-kube-stack` function.
The operator version and the resulting CRD versions are determined by the `AppVersion` in `Chart.yaml`

Manual Update:

```bash
wget https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v0.154.0/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml
wget https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v0.154.0/config/crd/bases/opentelemetry.io_opampbridges.yaml
wget https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v0.154.0/config/crd/bases/opentelemetry.io_instrumentations.yaml
wget https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/v0.154.0/config/crd/bases/opentelemetry.io_targetallocators.yaml
```
