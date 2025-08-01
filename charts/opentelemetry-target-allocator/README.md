# OpenTelemetry Target Allocator Helm Chart

The helm chart installs [OpenTelemetry Target Allocator](https://github.com/open-telemetry/opentelemetry-operator/tree/main/cmd/otel-allocator)
in kubernetes cluster.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.9+

## Installing the Chart

Add OpenTelemetry Helm repository:

```console
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
```

To install the chart with the release name my-target-allocator, run the following command:

```console
helm install my-target-allocator open-telemetry/opentelemetry-target-allocator
```

## Upgrading

See [UPGRADING.md](UPGRADING.md).

## Configuration

### Default configuration

By default this chart will deploy a Target Allocator to scan all namespaces for potential targets, finding all PodMonitor and ServiceMonitor custom resources compatible with the Prometheus Operator.

### Production-Ready Configuration

This chart includes comprehensive production-ready options for secure and scalable deployments:

#### Security Configuration

Configure security contexts for enhanced security:

```yaml
targetAllocator:
  # Pod-level security context
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 65534
    runAsGroup: 65534
    fsGroup: 65534
    seccompProfile:
      type: RuntimeDefault
  
  # Container-level security context
  securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    runAsUser: 65534
    runAsGroup: 65534
    capabilities:
      drop:
        - ALL
```

#### Resource Management

Set resource requests and limits for predictable performance:

```yaml
targetAllocator:
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
```

#### Health Monitoring

Configure health probes for Kubernetes health monitoring:

```yaml
targetAllocator:
  livenessProbe:
    httpGet:
      path: /
      port: http-port
    initialDelaySeconds: 30
    periodSeconds: 30
    timeoutSeconds: 5
    failureThreshold: 3
  
  readinessProbe:
    httpGet:
      path: /
      port: http-port
    initialDelaySeconds: 5
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
```

#### Deployment Considerations

**Important**: Target Allocator should run as a singleton (single replica) to avoid target allocation conflicts:

```yaml
targetAllocator:
  # Target Allocator must run as singleton
  replicaCount: 1
  
  # Configure pod distribution for node placement
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: node-role.kubernetes.io/control-plane
                operator: Exists
  
  # Ensure scheduling on stable nodes
  tolerations:
    - key: "node-role.kubernetes.io/control-plane"
      operator: "Exists"
      effect: "NoSchedule"
```

#### Node Selection

Deploy to specific nodes using node selectors and tolerations:

```yaml
targetAllocator:
  nodeSelector:
    monitoring: "true"
  
  tolerations:
    - key: "monitoring"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
```

### Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `targetAllocator.replicaCount` | Number of replicas | `1` |
| `targetAllocator.image.repository` | Image repository | `ghcr.io/open-telemetry/opentelemetry-operator/target-allocator` |
| `targetAllocator.image.tag` | Image tag | Chart appVersion |
| `targetAllocator.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `targetAllocator.imagePullSecrets` | Image pull secrets | `[]` |
| `targetAllocator.serviceAccount.create` | Create service account | `true` |
| `targetAllocator.serviceAccount.name` | Service account name | Generated |
| `targetAllocator.serviceAccount.annotations` | Service account annotations | `{}` |
| `targetAllocator.podSecurityContext` | Pod security context | See values.yaml |
| `targetAllocator.securityContext` | Container security context | See values.yaml |
| `targetAllocator.resources` | Resource requests and limits | See values.yaml |
| `targetAllocator.livenessProbe` | Liveness probe configuration | See values.yaml |
| `targetAllocator.readinessProbe` | Readiness probe configuration | See values.yaml |
| `targetAllocator.startupProbe` | Startup probe configuration | See values.yaml |
| `targetAllocator.nodeSelector` | Node selector | `{}` |
| `targetAllocator.tolerations` | Tolerations | `[]` |
| `targetAllocator.affinity` | Pod affinity | `{}` |
| `targetAllocator.podAnnotations` | Pod annotations | `{}` |
| `targetAllocator.podLabels` | Pod labels | `{}` |
| `targetAllocator.priorityClassName` | Priority class name | `""` |
| `targetAllocator.topologySpreadConstraints` | Topology spread constraints | `[]` |
| `targetAllocator.config.allocation_strategy` | Target allocation strategy | `consistent-hashing` |
| `targetAllocator.config.collector_namespace` | Collector namespace | Release namespace |
| `targetAllocator.config.collector_selector` | Collector selector | `{}` |
| `targetAllocator.config.prometheus_cr.enabled` | Enable Prometheus CR discovery | `true` |
| `targetAllocator.config.prometheus_cr.scrapeInterval` | Scrape interval | `30s` |
| `targetAllocator.config.prometheus_cr.service_monitor_selector` | ServiceMonitor selector | `{}` |
| `targetAllocator.config.prometheus_cr.pod_monitor_selector` | PodMonitor selector | `{}` |
| `targetAllocator.config.filter_strategy` | Filter strategy | `relabel-config` |
| `targetAllocator.config.config.scrape_configs` | Scrape configurations | `[]` |

### Limitations and Important Notes

⚠️ **Target Allocator Constraints**:

- **Singleton Requirement**: Target Allocator must run as a single replica (`replicaCount: 1`) to ensure consistent target allocation across collectors
- **Health Endpoints**: Uses root path (`/`) for health probes as Target Allocator may not support standard `/livez` and `/readyz` endpoints
- **State Management**: Target Allocator is stateless but coordinates target distribution, requiring singleton deployment
- **Network Access**: Requires access to Kubernetes API for ServiceMonitor/PodMonitor discovery

### Other configuration options

The [values.yaml](./values.yaml) file contains information about all other configuration
options for this chart.

For more examples see [Examples](examples).

### Examples

- [Production Ready](examples/production-ready/values.yaml) - Comprehensive production configuration
- [Consistent Hashing](examples/consistent-hashing/values.yaml) - Basic consistent hashing setup
- [Existing Service Account](examples/existing-service-account/values.yaml) - Use existing service account
- [Prometheus Scrape Config](examples/prometheus-scrape-config/values.yaml) - Custom scrape configurations
