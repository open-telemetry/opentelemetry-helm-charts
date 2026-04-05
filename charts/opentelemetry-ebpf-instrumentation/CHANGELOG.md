# Changelog

## OpenTelemetry eBPF Instrumentation

### v0.1.13 / 2026-04-05
- [Change] Bump OBI image to v0.7.0

### v0.1.12 / 2026-03-09
- [Change] Bump OBI image to v0.6.0

### v0.1.11 / 2026-02-17
- [Change] Bump OBI image to v0.5.0

### v0.1.10 / 2026-01-12
- [Change] Bump OBI image to v0.4.1

### v0.1.9 / 2025-12-15
- [Feature] Add Context Propagation Mode option to OBI config, defaults to "http,tcp"

### v0.1.8 / 2025-12-04
- [Change] Bump OBI image to v0.3.0
- [Fix] Get image tag from appVersion in Chart.yaml

### v0.1.7 / 2025-12-02
- [Change] Bump OBI image to v0.2.0
- [Fix] Fixes in OBI default config

### v0.1.6 / 2025-11-03
- [Change] Bump OBI image to v0.1.0

### v0.1.5 / 2025-10-21
- [Feat] Increase http, postgres default buffer sizes, add graphql payload extraction

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
