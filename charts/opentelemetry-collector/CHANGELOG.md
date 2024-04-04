# Changelog

## OpenTelemetry Collector

### v0.82.0 / 2024-04-04
- [Feat] Add metrics expiration configuration to the span metrics preset
- [Feat] Bump collector version to `0.97.0`

### v0.81.8 / 2024-04-02
- [Fix] Operator generate CRD missing environment variables

### v0.81.7 / 2024-03-28
- [Feat] Add new reduceResourceAttributes preset, which removes uids and other unnecessary resource attributes from metrics.

### v0.81.6 / 2024-03-26
- [Fix] Allow setting collectionInterval on spanMetricsMulti preset.

### v0.81.5 / 2024-03-25
- [Feat] Add new span metrics preset which supports different buckets per ottl expression.

### v0.81.4 / 2024-03-19
- [FIX] logsCollection, make force_flush_period configureable and disable by default

### v0.81.2 / 2024-03-15
- [FIX] Add logsCollection fix for empty log lines.

### v0.81.1 / 2024-03-06
- [FIX] Adjust target allocator config to work properly with label pod / service monitor selectors.

### v0.81.0 / 2024-03-06
- [CHORE] Bump Collector to 0.96.0
- [CHORE] Adjust target allocator config to be compatible with newer version of target allocator

### v0.80.2 / 2024-03-05
- [Fix] Ensure batch processor is always the last on in the pipeline.

### v0.80.1 / 2024-02-12
- [Feat] Exclude collector's debug / logging exporters logs, when collecting collector logs.

### v0.80.0 / 2024-02-09
- [CHORE] Pull upstream changes
- [CHORE] Bump Collector to 0.93.0
- [Fix] Go memory limit
- [Feat] Log Collector retry on failure enabled.

### v0.79.3 / 2024-02-05
- [FIX] Fix Target Allocator endpointslices issue

### v0.78.0 / 2023-12-13
- [CHORE] Pull upstream changes
- [CHORE] Bump Collector to 0.91.0
- [CHORE] Enable Go memory limit feature flag by default.

### v0.77.5 / 2023-11-30
- [FEAT] Add gke/autopilot distribution.

### v0.77.4 / 2023-11-28
- [FIX] Fix k8s.deployment.name transformation, in case the attribute already exists.

### v0.77.3 / 2023-11-27
- [FIX] Kubelet Stats use Node IP instead of Node name.
-
### v0.77.2 / 2023-11-26
- [FEAT] Add feature for replace patterns in span metrics preset.

### v0.77.1 / 2023-11-24
- [FEAT] Add spanmetricsconnector preset.

### v0.77.0 / 2023-11-13
- [BREAKING] Remove scraping of kube-state-metrics from kubernetesExtraMetrics preset.

### v0.76.3 / 2023-11-03
- [FIX] Append transform processor to the processor list instead of prepend

### v0.76.2 / 2023-11-03
- [FIX] Allow setting kube-state-metrics pod name.

### v0.76.2 / 2023-11-02
- [FIX] Add k8s.deployment.name attribute workaround for all signals

### v0.76.0 / 2023-10-31
- [CHORE] Bump Collector to 0.88.0

### V0.75.2 / 2023-10-31
- [FEAT] Add support for creating PriorityClass.

### V0.75.1 / 2023-10-30
- [FIX] Set insecure_skip_verify: true for kubelstats preset. See https://github.com/open-telemetry/opentelemetry-collector-contrib/releases/tag/v0.87.0 breaking changes section.

### v0.75.0 / 2023-10-30
- [CHORE] Bump Collector to 0.87.0

### v0.74.0 / 2023-10-30
- [CHORE] Bump Collector to 0.86.0

### v0.73.7 / 2023-10-26
- [CHORE] Pull upstream changes

### v0.73.0 / 2023-10-05

- [CHORE] Bump Collector to 0.85.0

### v0.72.0 / 2023-10-05

- [CHORE] Bump Collector to 0.84.0

### v0.71.3 / 2023-10-04

- [FIX] hostmetrics don't scrape /run/containerd/runc/* for filesystem metrics

### v0.71.2 / 2023-09-13

- Add metadata preset, to allow users add k8s.cluster.name and cx.otel_integration.name

### v0.71.1 / 2023-09-04

- Fix nodeSelector, affinity and tolerations CRD Generation
