# Upgrade guidelines

## 0.55.3 to 0.56.0

> [!WARNING]  
> As part of working towards using the [OpenTelemetry Collector Kubernetes Distro](https://github.com/open-telemetry/opentelemetry-collector-releases/tree/main/distributions/otelcol-k8s) by default, the chart now requires users to explicitly set a collector image repository. If you are already explicitly setting a collector image repository this breaking change does not affect you.

If you are using a OpenTelemetry Community distribution of the Collector we recommend you use `otel/opentelemetry-collector-k8s`, but carefully review the [components included in this distribution](https://github.com/open-telemetry/opentelemetry-collector-releases/blob/main/distributions/otelcol-k8s/manifest.yaml) to make sure it includes all the components you use in your configuration. In the future this distribution will become the default image used for the chart.

You can use the OpenTelemetry Collector Kubernetes Distro by adding these lines to your values.yaml:

```yaml
manager:
  collectorImage:
    repository: "otel/opentelemetry-collector-k8s"
```

If you want to stick with using the Contrib distribution, add these lines to your values.yaml:

```yaml
manager:
  collectorImage:
    repository: "otel/opentelemetry-collector-contrib"
```

For more details see [#1153](https://github.com/open-telemetry/opentelemetry-helm-charts/issues/1153).

## <0.54.0 to 0.55.2

> **_NOTE:_**  Versions 0.54.0 to 0.55.1 of the opentelemetry-operator helm chart should be avoided if providing user-managed certificates as file paths.

[Changes to functionality, and variable names used for providing user-managed webhook certificates](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/1121)

Below variables have been renamed to be consistent with the chart's naming format. v0.54.0 also has a bug fix which makes the chart now read the contents of the file paths provided by these variables, instead of just using the value of the variables.
```
admissionWebhooks.ca_file -> admissionWebhooks.caFile
admissionWebhooks.cert_file -> admissionWebhooks.certFile
admissionWebhooks.key_file -> admissionWebhooks.keyFile
```

## <0.50.0 to 0.50.0

Additional properties are not allowed anymore, so care must be taken that no old or misspelled ones are present anymore.
`helm show values open-telemetry/opentelemetry-operator --version 0.50.0` can be used to list the allowed values.

## <0.42.3 to 0.42.3

A type of flag `autoGenerateCert` has been changed, now it is an object with two attributes `enabled` and `recreate`.
If you previously set `autoGenerateCert` to `true` or `false` you have to set `autoGenerateCert.enabled` accordingly.

## <0.35.0 to 0.35.0
OpenTelemetry Operator [0.82.0](https://github.com/open-telemetry/opentelemetry-operator/releases/tag/v0.82.0) includes a change that allows setting the management state of custom resources [PR 1888](https://github.com/open-telemetry/opentelemetry-operator/pull/1888). Since helm doesn't upgrade CRDs ([documented](https://github.com/open-telemetry/opentelemetry-helm-charts/tree/main/charts/opentelemetry-operator#upgrade-chart)) it is critical to manually update CRDs from chart `0.35.0` or above, possibly using [this procedure](https://github.com/open-telemetry/opentelemetry-helm-charts/issues/69#issuecomment-1567285625).  If this step isn't taken existing otelcol CRs won't be reconciled by the operator.

## 0.27 to 0.28
[Allow using own self-signed certificate](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/760)

A new flag `admissionWebhooks.autoGenerateCert` has been added. If you want to keep benefiting from the helm generated certificate as in previous versions, you must set `admissionWebhooks.certManager.enabled` to `false` and `admissionWebhooks.autoGenerateCert` to `true`.

## 0.21 to 0.22.0
Kubernetes resource names will now use `{{opentelemetry-operator.fullname}}` as the default value which will change the name of many resources.
Some CI/CD tools might create duplicate resources when upgrading from an older version because of this change.
`fullnameOverride` can be used to keep `deployment` resource consistent with the same name during an upgrade.

## 0.16.0 to 0.17.0

The v0.17.0 helm chart version changes OpenTelemetry Collector image to the contrib version. If you want to use the core version, set `manager.collectorImage.repository` to `otel/opentelemetry-collector`.

## 0.15.0 to 0.16.0

Jaeger receiver no longer supports remote sampling. To be able to perform an update, it must be deactivated or replaced by a configuration of the [jaegerremotesampling](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/v0.61.0/extension/jaegerremotesampling) extension.<br/>
It is important that the `jaegerremotesampling` extension and the `jaegerreceiver` do not use the same port.<br/>To increase the collector version afterwards, the update must be triggered again by restarting the operator. Alternatively, the `OpenTelemetryCollector` CRD can be re-created. [otel-contrib#14707](https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/14707)

## 0.13.0 to 0.14.0

[Allow byo webhooks and cert](https://github.com/open-telemetry/opentelemetry-helm-charts/pull/411)

The ability to use admission webhooks has been moved from `admissionWebhooks.enabled` to `admissionWebhooks.create` as it now supports more use cases.

In order to completely disable admission webhooks you need to explicitly set the environment variable `ENABLE_WEBHOOKS: "false"` in `.Values.manager.env` .
