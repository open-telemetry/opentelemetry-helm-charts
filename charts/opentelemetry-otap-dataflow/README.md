# OpenTelemetry OTAP Dataflow Helm Chart

This Helm chart installs the [OpenTelemetry OTAP dataflow engine](https://github.com/open-telemetry/otel-arrow/tree/main/rust/otap-dataflow)
(`df-engine`) in a Kubernetes cluster.

The df-engine is a Rust pipeline engine that ingests OTLP telemetry, runs it
through an OTAP dataflow pipeline (receivers, processors, routers, exporters
described in a single `config.yaml`), and exports it to downstream backends.

## Prerequisites

- Kubernetes 1.24+
- Helm 4.0+

## Installing the Chart

Add the OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name `my-otap-dataflow`, run:

```console
helm install my-otap-dataflow open-telemetry/opentelemetry-otap-dataflow
```

## Configuration

The [values.yaml](./values.yaml) file documents the available configuration
options.

### Engine configuration

The OTAP pipeline is defined under `config.data` and rendered into a `ConfigMap`
mounted at `config.mountPath` (default `/etc/otap`) as `config.yaml`. The engine
is started with `--config /etc/otap/config.yaml`.

To supply your own pipeline, override `config.data`:

```yaml
config:
  data:
    version: otel_dataflow/v1
    groups:
      default:
        pipelines:
          main:
            type: otap
            nodes:
              otlp/ingest:
                type: receiver:otlp
                config:
                  protocols:
                    grpc:
                      listening_addr: "0.0.0.0:4317"
            connections: []
```

To mount an existing `ConfigMap` instead of generating one, set
`config.create: false` and `config.name: <existing-configmap>`.

### Secrets and environment variables

The engine resolves `${env:NAME}` references in its config at runtime. Inject
the referenced values through `extraEnv` (for example, a backend endpoint and
API token pulled from a `Secret`):

```yaml
extraEnv:
  - name: DT_ENDPOINT
    valueFrom:
      secretKeyRef:
        name: gateway-dynatrace
        key: DT_ENDPOINT
  - name: DT_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: gateway-dynatrace
        key: DT_API_TOKEN
```

### Ports

The chart exposes OTLP gRPC (`4317`), OTLP HTTP (`4318`), and the admin HTTP
interface (`8080`) by default. Toggle or repoint them under `ports`.
