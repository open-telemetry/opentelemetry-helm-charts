# OpenTelemetry Demo Helm Chart

The helm chart installs [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.23+
- Helm 3.9+

Since the OpenTelemetry demo does not build images targeting arm64 architecture **the chart is not supported in clusters running on
arm64 architectures**, such as kind/minikube running on Apple Silicon.

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-otel-demo, run the following command:

```console
helm install my-otel-demo open-telemetry/opentelemetry-demo
```

## Upgrading Chart

### To 0.13

Jaeger was moved to a Helm sub-chart instead of a local chart deployment. If you
had changes specified to the `observability.jaeger` parameter, those changes
will need to be re-implemented as sub-chart parameters under the top level
`jaeger` parameter instead.

## Chart Parameters

Chart parameters are separated in 4 general sections:
* Default - Used to specify defaults applied to all demo components
* Components - Used to configure the individual components (microservices) for
the demo
* Observability - Used to enable/disable dependencies
* Sub-charts - Configuration for all sub-charts

### Default parameters (applied to all demo components)

| Property                               | Description                                                                               | Default                                              |
|----------------------------------------|-------------------------------------------------------------------------------------------|------------------------------------------------------|
| `default.env`                          | Environment variables added to all components                                             | Array of several OpenTelemetry environment variables |
| `default.envOverrides`                 | Used to override individual environment variables without re-specifying the entire array. | `[]`                                                 |
| `default.image.repository`             | Demo components image name                                                                | `otel/demo`                                          |
| `default.image.tag`                    | Demo components image tag (leave blank to use app version)                                | `nil`                                                |
| `default.image.pullPolicy`             | Demo components image pull policy                                                         | `IfNotPresent`                                       |
| `default.image.pullSecrets`            | Demo components image pull secrets                                                        | `[]`                                                 |
| `default.schedulingRules.nodeSelector` | Node labels for pod assignment                                                            | `{}`                                                 |
| `default.schedulingRules.affinity`     | Man of node/pod affinities                                                                | `{}`                                                 |
| `default.schedulingRules.tolerations`  | Tolerations for pod assignment                                                            | `[]`                                                 |
| `default.securityContext`              | Demo components container security context                                                | `{}`                                                 |
| `serviceAccount`                       | The name of the ServiceAccount to use for demo components                                 | `""`                                                 |

### Component parameters

The OpenTelemetry demo contains several components (microservices). Each
component is configured with a common set of parameters. All components will
be defined within `components.[NAME]` where `[NAME]` is the name of the demo
component.

> **Note**
> The following parameters require a `components.[NAME].` prefix where `[NAME]`
> is the name of the demo component


| Parameter                            | Description                                                                                                | Default                                                       |
|--------------------------------------|------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|
| `enabled`                            | Is this component enabled                                                                                  | `true`                                                        |
| `useDefault.env`                     | Use the default environment variables in this component                                                    | `true`                                                        |
| `imageOverride.repository`           | Name of image for this component                                                                           | Defaults to the overall default image repository              |
| `imageOverride.tag`                  | Tag of the image for this component                                                                        | Defaults to the overall default image tag                     |
| `imageOverride.pullPolicy`           | Image pull policy for this component                                                                       | `IfNotPresent`                                                |
| `imageOverride.pullSecrets`          | Image pull secrets for this component                                                                      | `[]`                                                          |
| `servicePort`                        | Service port used for this component                                                                       | `nil`                                                         |
| `ports`                              | Array of ports to open for deployment and service of this component                                        | `[]`                                                          |
| `env`                                | Array of environment variables added to this component                                                     | Each component will have its own set of environment variables |
| `envOverrides`                       | Used to override individual environment variables without re-specifying the entire array                   | `[]`                                                          |
| `resources`                          | CPU/Memory resource requests/limits                                                                        | Each component will have a default memory limit set           |
| `schedulingRules.nodeSelector`       | Node labels for pod assignment                                                                             | `{}`                                                          |
| `schedulingRules.affinity`           | Man of node/pod affinities                                                                                 | `{}`                                                          |
| `schedulingRules.tolerations`        | Tolerations for pod assignment                                                                             | `[]`                                                          |
| `securityContext`                    | Container security context to define user ID (UID), group ID (GID) and other security policies             | `{}`                                                          |
| `podAnnotations`                     | Pod annotations for this component                                                                         | `{}`                                                          |
| `ingress.enabled`                    | Enable the creation of Ingress rules                                                                       | `false`                                                       |
| `ingress.annotations`                | Annotations to add to the ingress rule                                                                     | `{}`                                                          |
| `ingress.ingressClassName`           | Ingress class to use. If not specified default Ingress class will be used.                                 | `nil`                                                         |
| `ingress.hosts`                      | Array of Hosts to use for the ingress rule.                                                                | `[]`                                                          |
| `ingress.hosts[].paths`              | Array of paths / routes to use for the ingress rule host.                                                  | `[]`                                                          |
| `ingress.hosts[].paths[].path`       | Actual path route to use                                                                                   | `nil`                                                         |
| `ingress.hosts[].paths[].pathType`   | Path type to use for the given path. Typically this is `Prefix`.                                           | `nil`                                                         |
| `ingress.hosts[].paths[].port`       | Port to use for the given path                                                                             | `nil`                                                         |
| `ingress.additionalIngresses`        | Array of additional ingress rules to add. This is handy if you need to differently annotated ingress rules | `[]`                                                          |
| `ingress.additionalIngresses[].name` | Each additional ingress rule needs to have a unique name                                                   | `nil`                                                         |
| `command`                            | Command & arguments to pass to the container being spun up for this service                                | `[]`                                                          |
| `configuration`                      | Configuration for the container being spun up; will create a ConfigMap, Volume and VolumeMount             | `{}`                                                          |

### Observability parameters

| Parameter                          | Description                                   | Default |
|------------------------------------|-----------------------------------------------|---------|
| `observability.otelcol.enabled`    | Enables the OpenTelemetry Collector sub-chart | `true`  |
| `observability.jaeger.enabled`     | Enables the Jaeger sub-chart                  | `true`  |
| `observability.prometheus.enabled` | Enables the Prometheus sub-chart              | `true`  |
| `observability.grafana.enabled`    | Enables the Grafana sub-chart                 | `true`  |

### Sub-charts

The OpenTelemetry Demo Helm chart depends on 4 sub-charts:
* OpenTelemetry Collector
* Jaeger
* Prometheus
* Grafana

Parameters for each sub-chart can be specified within that sub-chart's
respective top level. This chart will override some of the dependent sub-chart
parameters by default. The overriden parameters are specified below.

#### OpenTelemetry Collector

> **Note**
> The following parameters have a `opentelemetry-collector.` prefix.

| Parameter        | Description                                        | Default                                                  |
|------------------|----------------------------------------------------|----------------------------------------------------------|
| `nameOverride`   | Name that will be used by the sub-chart release    | `otelcol`                                                |
| `mode`           | The Deployment or Daemonset mode                   | `deployment`                                             |
| `resources`      | CPU/Memory resource requests/limits                | 100Mi memory limit                                       |
| `service.type`   | Service Type to use                                | `ClusterIP`                                              |
| `ports`          | Ports to enabled for the collector pod and service | `metrics` is enabled and `prometheus` is defined/enabled |
| `podAnnotations` | Pod annotations                                    | Annotations leveraged by Prometheus scrape               |
| `config`         | OpenTelemetry Collector configuration              | Configuration required for demo                          |

#### Jaeger

> **Note**
> The following parameters have a `jaeger.` prefix.

| Parameter                      | Description                                        | Default                                                               |
|--------------------------------|----------------------------------------------------|-----------------------------------------------------------------------|
| `provisionDataStore.cassandra` | Provision a cassandra data store                   | `false` (required for AllInOne mode)                                  |
| `allInOne.enabled`             | Enable All in One In-Memory Configuration          | `true`                                                                |
| `allInOne.args`                | Command arguments to pass to All in One deployment | `["--memory.max-traces", "10000", "--query.base-path", "/jaeger/ui"]` |
| `allInOne.resources`           | CPU/Memory resource requests/limits for All in One | 275Mi memory limit                                                    |
| `storage.type`                 | Storage type to use                                | `none` (required for AllInOne mode)                                   |
| `agent.enabled`                | Enable Jaeger agent                                | `false` (required for AllInOne mode)                                  |
| `collector.enabled`            | Enable Jaeger Collector                            | `false` (required for AllInOne mode)                                  |
| `query.enabled`                | Enable Jaeger Query                                | `false` (required for AllInOne mode)                                  |

#### Prometheus

> **Note**
> The following parameters have a `prometheus.` prefix.

| Parameter                            | Description                                    | Default                                                   |
|--------------------------------------|------------------------------------------------|-----------------------------------------------------------|
| `alertmanager.enabled`               | Install the alertmanager                       | `false`                                                   |
| `configmapReload.prometheus.enabled` | Install the configmap-reload container         | `false`                                                   |
| `kube-state-metrics.enabled`         | Install the kube-state-metrics sub-chart       | `false`                                                   |
| `prometheus-node-exporter.enabled`   | Install the Prometheus Node Exporter sub-chart | `false`                                                   |
| `prometheus-pushgateway.enabled`     | Install the Prometheus Push Gateway sub-chart  | `false`                                                   |
| `server.global.scrape_interval`      | How frequently to scrape targets by default    | `5s`                                                      |
| `server.global.scrap_timeout`        | How long until a scrape request times out      | `3s`                                                      |
| `server.global.evaluation_interval`  | How frequently to evaluate rules               | `30s`                                                     |
| `service.servicePort`                | Service port used                              | `9090`                                                    |
| `serverFiles.prometheus.yml`         | Prometheus configuration file                  | Scrape config to get metrics from OpenTelemetry collector |

#### Grafana

> **Note**
> The following parameters have a `grafana.` prefix.

| Parameter             | Description                                        | Default                                                              |
|-----------------------|----------------------------------------------------|----------------------------------------------------------------------|
| `grafana.ini`         | Grafana's primary configuration                    | Enables anonymous login, and proxy through the frontendProxy service |
| `adminPassword`       | Password used by `admin` user                      | `admin`                                                              |
| `datasources`         | Configure grafana datasources (passed through tpl) | Prometheus and Jaeger data sources                                   |
| `dashboardProviders`  | Configure grafana dashboard providers              | Defines a `default` provider based on a file path                    |
| `dashboardConfigMaps` | ConfigMaps reference that contains dashboards      | Dashboard config map deployed with this Helm chart                   |
