# OpenTelemetry Operator Helm Chart

The Helm chart installs [OpenTelemetry Operator](https://github.com/open-telemetry/opentelemetry-operator) in Kubernetes cluster.
The OpenTelemetry Operator is an implementation of a [Kubernetes Operator](https://www.openshift.com/learn/topics/operators).
At this point, it has [OpenTelemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) as the only managed component.

## Prerequisites

- Kubernetes 1.19+ is required for OpenTelemetry Operator installation
- Helm 3.0+

### TLS Certificate Requirement

In Kubernetes, in order for the API server to communicate with the webhook component, the webhook requires a TLS
certificate that the API server is configured to trust. There are three ways for you to generate the required TLS certificate.

  - The easiest and default method is to install the [cert-manager](https://cert-manager.io/docs/) and set `admissionWebhooks.certManager.enabled` to `true`.
    In this way, cert-manager will generate a self-signed certificate. _See [cert-manager installation](https://cert-manager.io/docs/installation/kubernetes/) for more details._
  - You can also provide your own Issuer by configuring the `admissionWebhooks.certManager.issuerRef` value. You will need
    to specify the `kind` (Issuer or ClusterIssuer) and the `name`. Note that this method also requires the installation of cert-manager.
  - The last way is to manually modify the secret where the TLS certificate is stored. Make sure you set `admissionWebhooks.certManager.enabled` to `false` first.
    - Create the namespace for the OpenTelemetry Operator and the secret
      ```console
      $ kubectl create namespace opentelemetry-operator-system
      ```
    - Config the TLS certificate using `kubectl create` command
      ```console
      $ kubectl create secret tls opentelemetry-operator-controller-manager-service-cert \
          --cert=path/to/cert/file \
          --key=path/to/key/file \
          -n opentelemetry-operator-system
      ```
      You can also do this by applying the secret configuration.
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

## Add Repository

```console
$ helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
$ helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Chart

If you didn't create the namespace `opentelemetry-operator-system` before (steps in the third method to generate the TLS cert),
the OpenTelemetry Operator chart will be installed in the namespace automatically. The installation command example is as below.

```console
$ helm install \
  my-opentelemetry-operator open-telemetry/opentelemetry-operator
```

However, if you create the namespace and place the TLS cert in the desired secret, you will need to set `createNamespace`
to `false` to make sure Helm won't try to create an existing namespace, which would cause an error. Installation command example is as below.

```console
$ helm install \
  my-opentelemetry-operator open-telemetry/opentelemetry-operator \
  --set createNamespace=false
```

Note that `--namespace` option here won't affect where the OpenTelemetry Operator and other resources this chart contains are installed.
It will only affect on where the Helm chart release info is stored, which is `default` namespace by default.

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

If the namespace wasn't created by the Helm chart, you'll need to manually remove it as well:

```console
$ kubectl delete ns opentelemetry-operator-system
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

If you want to get more control of the OpenTelemetry Collector and create a standalone application, Deployment would
be your choice. With Deployment, you can relatively easily scale up the Collector to monitor more targets, roll back
to an early version if anything unexpected happens, pause the Collector, etc. In general, you can manage your Collector
instance just as an application.

The following example configuration deploys the Collector as Deployment resource. The receiver is Jaeger receiver and
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

DaemonSet should satisfy your needs if you want the Collector run as an agent in your Kubernetes nodes.
In this case, every Kubernetes node will have its own Collector copy which would monitor the pods in it.

The following example configuration deploys the Collector as DaemonSet resource. The receiver is Jaeger receiver and
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
        loglevel: debug

    service:
      pipelines:
        traces:
          receivers: [jaeger]
          processors: []
          exporters: [logging]
EOF
```

### StatefulSet Mode
There are basically three main advantages to deploy the Collector as the StatefulSet:
- Predictable names of the Collector instance will be expected \
  If you use above two approaches to deploy the Collector, the pod name of your Collector instance will be unique (its name plus random sequence).
  However, each Pod in a StatefulSet derives its hostname from the name of the StatefulSet and the ordinal of the Pod (my-col-0, my-col-1, my-col-2, etc.).
- Rescheduling will be arranged when a Collector replica fails \
  If a Collector pod fails in the StatefulSet, Kubernetes will attempt to reschedule a new pod with the same name to the same node. Kubernetes will also attempt
  to attach the same sticky identity (e.g., volumes) to the new pod.

The following example configuration deploys the Collector as StatefulSet resource with three replicas. The receiver
is Jaeger receiver and the exporter is logging exporter.

```console
$ kubectl apply -f - <<EOF
apiVersion: opentelemetry.io/v1alpha1
kind: OpenTelemetryCollector
metadata:
  name: my-collector
spec:
  mode: statefulset
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
The biggest advantage of the sidecar mode is that it allows people to offload their telemetry data as fast and reliable as possible from their applications.
This Collector instance will work on the container level and no new pod will be created, which is perfect to keep your Kubernetes cluster clean and easily to be managed.
Moreover, you can also use the sidecar mode when you want to use a different collect/export strategy, which just suits this application.

Once a Sidecar instance exists in a given namespace, you can have your deployments from that namespace to get a sidecar
by either adding the annotation `sidecar.opentelemetry.io/inject: true` to the pod spec of your application, or to the namespace.

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
