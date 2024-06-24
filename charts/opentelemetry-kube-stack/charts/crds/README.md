# OpenTelemetry Collector CRDs

This chart contains the CRDs for _*installation*_ only right now for the opentelemetry-operator. This allows the OpenTelemetry Kubernetes Stack chart to work on install. You can see more discussion about this [here](https://github.com/open-telemetry/opentelemetry-helm-charts/issues/677) and [here](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/1203).

This approach is inspired by the kube-prometheus-stack approach which you can see discussion on [here](https://github.com/prometheus-community/helm-charts/issues/3548).

> [!NOTE]
> This chart explicitly _does not_ support the conversion webhook that is currently in the opentelemetry-operator chart. This is because the opentelemetry-kube-stack chart will only work with v1beta1 CRDs. This chart is not meant for use with v1alpha1 Collector CRDs.

# Upgrade Notes

Right now, upgrades are NOT handled by this chart, however that could change in the future. This is what is run to bring in the CRDs today.

```bash
wget https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_opentelemetrycollectors.yaml
wget https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_opampbridges.yaml
wget https://raw.githubusercontent.com/open-telemetry/opentelemetry-operator/main/config/crd/bases/opentelemetry.io_instrumentations.yaml\n
```
