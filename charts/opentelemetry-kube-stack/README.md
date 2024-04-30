# OpenTelemetry Kube Stack Helm Chart

> [!CAUTION]
> This chart is under active development and is not meant to be installed yet.
> Right now, nothing is included with this deployment.

This Helm chart serves as a quickstart for OpenTelemetry in a Kubernetes environment. The chart installs an [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) and a suite of collectors that help you get started with OpenTelemetry metrics, traces, and logs.

## Prerequisites

- Kubernetes 1.24+ is required for OpenTelemetry Operator installation
- Helm 3.9+

### TLS Certificate Requirement

<details>
<summary>Cert Manager Dependendency</summary>
<br>
In Kubernetes, in order for the API server to communicate with the webhook component, the webhook requires a TLS
certificate that the API server is configured to trust. There are a few different ways you can use to generate/configure the required TLS certificate.

- The easiest and default method is to install the [cert-manager](https://cert-manager.io/docs/) and set `opentelemetry-operator.admissionWebhooks.certManager.enabled` to `true`.
  In this way, cert-manager will generate a self-signed certificate. _See [cert-manager installation](https://cert-manager.io/docs/installation/kubernetes/) for more details._
- You can provide your own Issuer by configuring the `opentelemetry-operator.admissionWebhooks.certManager.issuerRef` value. You will need
  to specify the `kind` (Issuer or ClusterIssuer) and the `name`. Note that this method also requires the installation of cert-manager.
- You can use an automatically generated self-signed certificate by setting `opentelemetry-operator.admissionWebhooks.certManager.enabled` to `false` and `opentelemetry-operator.admissionWebhooks.autoGenerateCert.enabled` to `true`. Helm will create a self-signed cert and a secret for you.
- You can use your own generated self-signed certificate by setting both `opentelemetry-operator.admissionWebhooks.certManager.enabled` and `opentelemetry-operator.admissionWebhooks.autoGenerateCert.enabled` to `false`. You should provide the necessary values to `opentelemetry-operator.admissionWebhooks.cert_file`, `opentelemetry-operator.admissionWebhooks.key_file`, and `opentelemetry-operator.admissionWebhooks.ca_file`.
- You can sideload custom webhooks and certificate by disabling `.Values.opentelemetry-operator.admissionWebhooks.create` and `opentelemetry-operator.admissionWebhooks.certManager.enabled` while setting your custom cert secret name in `opentelemetry-operator.admissionWebhooks.secretName`
- You can disable webhooks altogether by disabling `.Values.opentelemetry-operator.admissionWebhooks.create` and setting env var to `ENABLE_WEBHOOKS: "false"`
</details>

## Add Repository

```console
$ helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
$ helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Chart

```console
$ helm install \
  opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

If you created a custom namespace, like in the TLS Certificate Requirement section above, you will need to specify the namespace with the `--namespace` helm option:

```console
$ helm install --namespace opentelemetry-operator-system \
  opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

If you wish for helm to create an automatically generated self-signed certificate, make sure to set the appropriate values when installing the chart:

```console
$ helm install  --set opentelemetry-operator.admissionWebhooks.certManager.enabled=false --set admissionWebhooks.autoGenerateCert.enabled=true \
  opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Chart

The following command uninstalls the chart whose release name is opentelemetry-kube-stack.

```console
$ helm uninstall opentelemetry-kube-stack
```

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

This will remove all the Kubernetes components associated with the chart and deletes the release.

The OpenTelemetry Collector CRD created by this chart won't be removed by default and should be manually deleted:

```console
$ kubectl delete crd opentelemetrycollectors.opentelemetry.io
$ kubectl delete crd opampbridges.opentelemetry.io
$ kubectl delete crd instrumentations.opentelemetry.io
```

## Upgrade Chart

```console
$ helm upgrade opentelemetry-kube-stack open-telemetry/opentelemetry-kube-stack
```

Please note that by default, the chart will be upgraded to the latest version. If you want to upgrade to a specific version,
use `--version` flag.

With Helm v3.0, CRDs created by this chart are not updated by default and should be manually updated.
Consult also the [Helm Documentation on CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions).

_See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation._

## Configuration

The following command will show all the configurable options with detailed comments.

```console
$ helm show values open-telemetry/opentelemetry-kube-stack
```

When using this chart as a subchart, you may want to unset certain default values. Since Helm v3.13 values handling is improved and null can now consistently be used to remove values (e.g. to remove the default CPU limits).
