# Changelog

## OpenTelemetry eBPF Instrumentation

### v0.1.4 / 2025-08-11
- [Fix] add toleration, affinity and nodeSelector to k8s cache deployment

### v0.1.3 / 2025-08-04
- [Fix] Fix redis db cache enable to enabled

### v0.1.2 / 2025-07-13
- [Feat] Add context propagation value in `values.yaml` ([port from beyla](https://github.com/grafana/beyla/commit/37749b58ef616bbb304216ee5407ba95bae9c6fb))
- [Feat] Change default values to add redis db cache, k8s cache and mysql large buffers
- [Feat] Change default of attributes.kubernetes.enabled to true

### v0.1.1 / 2025-06-17
- [Feat] Use new `otel/opentelemetry-ebpf-k8s-cache` image instead of beyla one
- [Fix] rename `otel-ebpf-k8s-cache` to `opentelemetry-ebpf-instrumentation-k8s-cache`

### v0.1.0 / 2025-06-15
- [Feat] New chart for OpenTelemetry eBPF Instrumentation
