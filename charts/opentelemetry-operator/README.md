# OpenTelemetry Operator Helm Chart

The Helm chart installs [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) in Kubernetes cluster.
The OpenTelemetry Operator is an implementation of a [Kubernetes Operator](https://www.openshift.com/learn/topics/operators).
At this point, it has [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) as the only managed component.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+

### TLS Certificate Requirement

In Kubernetes, in order for the API server to communicate with the webhook component, the webhook requires a TLS
certificate that the API server is configured to trust. There are three ways for you to generate the required TLS certificate.

  - The easiest and default method is to install the cert-manager and keeps `admissionWebhooks.certManager.enabled` to `true`.
    In this way, cert-manager will generate a self-signed certificate. _See [cert-manager installation](https://cert-manager.io/docs/installation/kubernetes/) for the instruction._
  - You can also provide your own Issuer by configuring the `admissionWebhooks.certManager.issuerRef` value. You will need
    to specify the `kind` (Issuer or ClusterIssuer) and the `name`. Noted that this method also requires the installation of cert-manager.
  - The last way is to manually modify the secret where the TLS certificate is stored. You can either do this before installation
    or after.
    - To do this before installation, you don't have to install cert-manager. Please set `admissionWebhooks.certManager.enabled` to `false`.
      - Create namespace for the OTEL Operator and the secret
        ```console
        $ kubectl create namespace opentelemetry-operator-system
        ```
      - Config the TLS certificate
        ```console
        $ kubectl apply -f - <<EOF
          apiVersion: v1
          kind: Secret
          metadata:
            name: opentelemetry-operator-controller-manager-service-cert
            namespace: opentelemetry-operator-system
          type: kubernetes.io/tls
          data:
            tls.crt: |
                # your signed cert
            tls.key: |
                # your private key
          EOF
        ```
        You can also do this using `kubectl create` command.
        ```console
        $ kubectl create secret tls opentelemetry-operator-controller-manager-service-cert \
            --cert=path/to/cert/file \
            --key=path/to/key/file \
            -n opentelemetry-operator-system
        ```
    - To do this after installation, you will have to install cert-manager first. Once the Operator is ready, you can override
      the secret by putting your certificate there. What you need to do is the same as the second step above.

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

Please note that by default, the chart will be upgraded to the latest version. If you want to upgrade to a specific version,
use `--version` flag.

With Helm v3.0, CRDs created by this chart are not updated by default and should be manually updated.
Consult also the [Helm Documentation on CRDs](https://helm.sh/docs/chart_best_practices/custom_resource_definitions).

_See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation._

## Configuration

The following command will show all the configurable options with detailed comments.

```console
$ helm show values open-telemetry/opentelemetry-operator
```

## Install OpenTelemetry Collector

_See [OpenTelemetry website](https://opentelemetry.io/docs/collector/) for more details about the Collector_

Once the opentelemetry-operator deployment is ready, you can deploy OpenTelemetry Collector in our Kubernetes
cluster.

The Collector can be deployed as one of four modes: Deployment, DaemonSet, StatefulSet and Sidecar. The default
mode is Deployment. We will introduce the benefits and use cases of each mode as well as giving an example for each.

### Deployment Mode

If you want to get more control of the OpenTelemetry collector and create a standalone application, Deployment would
be your choice. With Deployment, you can relatively easily scale up the collector to monitor more targets, roll back
to an early version if anything unexpected happens, pause the collector, etc. In general, you can manage your collector
instance just as an application.

The following example configuration deploys the Collector as Deployment resource. The receiver is jaeger-receiver and
the exporter is logging exporter.

```console
$ kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: my-collector
spec:
  mode: deployment # This configuration is omittable.
  config: |
    receivers:
      jaeger:
        protocols:
          grpc:
    processors:

    exporters:
      logging:

    service:
      pipelines:
        traces:
          receivers: [jaeger]
          processors: []
          exporters: [logging]
EOF
```

### DaemonSet Mode

DaemonSet should satisfy your most basic needs and is the most common method to deploy OpenTelemetry collector.
In this case, every Kubernetes node will have its own collector copy which would monitor the pods in it.

The following example configuration deploys the Collector as DaemonSet resource. The receiver is jaeger-receiver and
the exporter is logging exporter.

```console
$ kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: my-collector
spec:
  mode: daemonset
  config: |
    receivers:
      jaeger:
        protocols:
          grpc:
    processors:

    exporters:
      logging:

    service:
      pipelines:
        traces:
          receivers: [jaeger]
          processors: []
          exporters: [logging]
EOF
```

### StatefulSet Mode
If you want your collector to have stable persistent identities or storage, you should choose StatefulSet.
Take Prometheus metrics for example, if you use above two approaches, the metrics collected from the receiver will
be stored locally by default, which is ephemeral. However, StatefulSet allows you to configure a persistent storage
interface called PersistentVolume. PersistentVolume will maintain the historical metrics data and even survive pods
restart. This feature gives you the possibility that you can reconstruct the time-series logs.

The following example configuration deploys the Collector as StatefulSet resource with three replicas. The receiver
is jaeger-receiver and the exporter is logging exporter.

```console
$ kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: my-collector
spec:
  mode: statefulset
  volumeMounts:
    - mountPath: "/usr/share/test-volume"
      name: test-volume
  volumeClaimTemplates:
    - metadata:
        name: "test-volume"
      spec:
        accessModes: [ "ReadWriteOnce" ]
        storageClassName: "standard"
        resources:
          requests:
            storage: 1Gi
  replicas: 3
  config: |
    receivers:
      jaeger:
        protocols:
          grpc:
    processors:

    exporters:
      logging:

    service:
      pipelines:
        traces:
          receivers: [jaeger]
          processors: []
          exporters: [logging]
EOF
```

### Sidecar Mode
If all you want to monitor is a single application, then collector as the sidecar would be the best fit.
This collector instance will work on the container level and no new pods or other workload resources are needed,
which is perfect to keep your Kubernetes cluster clean. Moreover, you can also use the sidecar mode when you want
to use a different collect/export strategy, which just suits this application.

You can deploy the sidecar mode by setting the pod annotation `sidecar.opentelemetry.io/inject` to either `true`,
or to the name of a concrete `OpenTelemetryCollector` from the same namespace.

_See the [OpenTelemetry Operator github repository](https://github.com/open-telemetry/opentelemetry-operator) for more detailed information._

```console
$ kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: sidecar-for-my-app
spec:
  mode: sidecar
  config: |
    receivers:
      jaeger:
        protocols:
          grpc:
    processors:

    exporters:
      logging:

    service:
      pipelines:
        traces:
          receivers: [jaeger]
          processors: []
          exporters: [logging]
EOF

$ kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  annotations:
    sidecar.opentelemetry.io/inject: "true"
spec:
  containers:
  - name: myapp
    image: jaegertracing/vertx-create-span:operator-e2e-tests
    ports:
      - containerPort: 8080
        protocol: TCP
EOF
```
