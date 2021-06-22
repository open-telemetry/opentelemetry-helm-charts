# OpenTelemetry Operator Helm Chart

The Helm chart installs [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) in Kubernetes cluster.
The OpenTelemetry Operator is an implementation of a [Kubernetes Operator](https://www.openshift.com/learn/topics/operators).
At this point, it has [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) as the only managed component.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- cert-manager
  - To install OpenTelemetry Operator in Kubernetes cluster, you must have cert-manager installed first.
    _See [cert-manager installation](https://cert-manager.io/docs/installation/kubernetes/) for the instruction._

## Add Repository

```console
$ helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
$ helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Chart

The following command installs the chart with the release name my-opentelemetry-operator in the namespace opentelemetry-operator-system.

```console
$ helm install \
  my-opentelemetry-operator open-telemetry/opentelemetry-operator \
  --namespace opentelemetry-operator-system \
  --create-namespace
```

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Chart

The following command uninstalls the chart whose release name is my-opentelemetry-operator.

```console
$ helm uninstall my-opentelemetry-operator
```

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

This will remove all the Kubernetes components associated with the chart and deletes the release.

The OpenTelemetry Collector CRD created by this chart won't be removed by default and should be manually deleted:

```console
$ kubectl delete crd opentelemetrycollectors.opentelemetry.io
```

## Upgrade Chart

```console
$ helm upgrade my-opentelemetry-operator open-telemetry/opentelemetry-operator
```

With Helm v3.0, CRDs created by this chart are not updated by default and should be manually updated.
Consult also the [Helm Documentation on CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions).

_See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation._

## Configuration

The folloing command will show all the configurable options with detailed comments.

```console
$ helm show values open-telemetry/opentelemetry-operator
```
