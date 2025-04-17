# Changelog

## OpenTelemetry Collector

## v0.112.2 / 2025-04-18
- [Feat] Add scrapeAll preset to collect all cadisor metrics

## v0.112.1 / 2025-04-14
- [Fix] fix dbMetrics use db.collection.name instead of db.collection_name

### v0.112.0 / 2024-04-11
- [Feat] Update Collector to v0.123.0

### v0.111.0 / 2025-04-04
- [Feat] Update Collector to v0.122.1

## v0.110.8 / 2025-04-03
- [Fix] Filter only Pods from standard Kubernetes Workloads in kubernetesResource preset.

## v0.110.7 / 2025-04-02
- [Fix] Filter only Pods from standard Kubernetes Workloads in kubernetesResource preset.

## v0.110.6 / 2025-04-01
- [Fix] extraDimensions support for dbMetrics in spanMetrics preset

## v0.110.5 / 2025-03-31
- [Fix] extraDimensions support for dbMetrics in spanMetrics preset

## v0.110.4 / 2025-03-31
- [Feat] Add extraDimensions support for dbMetrics in spanMetrics preset

## v0.110.3 / 2025-03-31
- [Fix] Configure hostEntityEvents preset to require hostMetrics preset to be enabled

## v0.110.2 / 2025-03-20
- [Fix] Fix OpentelemetryCollector crd generation

## v0.110.1 / 2025-03-20
- [Fix] Fix OpentelemetryCollector crd generation

## v0.110.0 / 2025-03-06
- [Feat] Add profiling preset

### v0.109.0 / 2025-03-06
- [Feat] Update Collector to v0.121.0

### v0.108.1 / 2025-03-05
- [Feat] Add headSampling preset to configure probabilistic sampling for traces

### v0.108.0 / 2025-02-28
- [Feat] Update Collector to v0.120.0

### v0.107.1 / 2025-02-27
- [Fix] Change telemetry.metrics.address to metric reader

### v0.107.0 / 2025-02-27
- [Feat] Update Collector to v0.119.0

### v0.106.4 / 2025-02-20
- [Fix] Filter only Pods from standard kubernetes Workloads in kubernetesResource presets.

### v0.106.3 / 2025-02-17
- [Fix] `spanMetrics.transformStatements` are correctly created even when `spanMetrics.dbMetrics` is not enabled.

### v0.106.2 / 2025-02-05
- [Feat] Add support for CUSTOM autoscaling mode alongside HPA mode

### v0.106.1 / 2025-02-04
- [Feat] Ensure the `memory_limiter` processor is always the first in the pipeline.

### v0.106.0 / 2025-02-04
- [Feat] Update Collector to v0.118.0

### v0.105.3 / 2025-02-03
- [Feat] Add configuration for startup probe.

### v0.105.2 / 2025-01-31
- [Feat] Add extraConfig to allow adding extra processors, receivers, exporters, and connectors to the collector.

### v0.105.1 / 2025-01-14
- [Fix] Add missing `source_identifier` to `presets.logsCollection.multilineConfigs`

### v0.105.0 / 2025-01-09
- [Feat] Bump collector version to `0.117.0`

### v0.104.1 / 2025-01-09
- [Feat] change entity endpoint version to v1

### v0.104.0 / 2025-01-08
- [Feat]  add entity interval for objects coming from kubernetesResources preset.

### v0.103.0 / 2025-01-03
- [Feat] Bump collector version to `0.116.1`

### v0.102.0 / 2025-01-02
- [Fix] Revert the change in metrics telemetry service host from `0.0.0.0` to `${env:MY_POD_IP}`
  since https://github.com/open-telemetry/opentelemetry-operator/pull/3531 is merged and released.
  If you are using the OpenTelemetry Operator and the Collector CRD, please update the Operator to
  version `0.116.0` or later.

### v0.101.0 / 2024-12-31

- [Feat] Add job name to pod association for k8s attributes.

### v0.99.0 / 2024-12-05
- [Feat] Bump collector version to `0.115.1`

### v0.98.7 / 2024-12-04
- [Fix] Target Allocator configmap name conflicting with collector configmap.

### v0.98.6 / 2024-12-02
- [Fix] Create the Target Allocator service only when applicable.

### v0.98.5 / 2024-11-28
- [Feat] Adding new configs to the Target Allocator.

### v0.98.4 / 2024-11-28
- [Fix] Make the metrics telemetry service listen on `0.0.0.0` instead of using shell var expansion to resolve the pod IP.

### v0.98.3 / 2024-11-26
- [Feat] Add the new `errorTracking` preset.

### v0.98.2 / 2024-11-20
- [Fix] Add missing `max_batch_size` to all applicable recombine processors in the `logsCollection` preset.

### v0.98.1 / 2024-11-06
- [Feat] add azure/ec2 resource detecion for kubernetes resource collection.

### v0.98.0 / 2024-11-05
- [Feat] Add support for scraping cadvisor metrics per node on daemonset

### v0.97.1 / 2024-11-05
- [Feat] add aks/eks/gcp resource detecion for kubernetes resource collection.

### v0.97.0 / 2024-11-04
- [Feat] logsCollection preset allow changing max_batch_size
- [Fix] Revert collector version to `0.111.0` due to https://github.com/open-telemetry/opentelemetry-collector-contrib/issues/35990

### v0.96.0 / 2024-10-24
- [Feat] Bump collector version to `0.112.0`

### v0.95.4 / 2024-10-22
- [Fix] dbMetrics wrongly generated filter connector instead of filter processor

### v0.95.3 / 2024-10-22
- [Fix] dbMetrics silent transform/db processor

### v0.95.2 / 2024-10-22
- [Feat] add dbMetrics option to spanmetrics preset

### v0.93.3 / 2024-09-23
- [Fix] agent_description.non_identifying_attributes expected a map, got 'slice'

### v0.93.2 / 2024-09-20
- [Fix] Change opamp poll interval to 2 minutes

### v0.93.1 / 2024-09-12
- [Fix] Allow changing spanmetrics namespace

### v0.93.0 / 2024-09-11
- [Feat] Bump collector version to `0.108.0`

### v0.92.0 / 2024-09-04
- [Feat] Add support for taeget allocator static config.

### v0.91.0 / 2024-08-30
- [Feat] Bump collector version to `0.108.0`

### v0.90.0 / 2024-08-19
- [Fix] ignore process name not found errors for hostmetrics process preset

### v0.89.0 / 2024-08-16
- [Feat] Bump collector version to `0.107.0`

### v0.88.7 / 2024-08-14
- [Fix] add k8s.cluster.name to resource catalog events

### v0.88.6 / 2024-08-07
- [Feat] Allow configuration of scrape interval value for target allocator prometheus custom resources.

### v0.88.5 / 2024-08-05
- [Feat] add more system attributes to host entity event preset

### v0.88.4 / 2024-08-05
- [Fix] Add fleet management preset

### v0.88.3 / 2024-08-05
- [Feat] add more attributes to host entity event preset

### v0.88.2 / 2024-08-01
- [Fix] ignore exe errors for hostmetrics process preset

### v0.88.1 / 2024-08-01
- [Feat] Bump collector version to `0.106.1`

### v0.88.0 / 2024-07-31
- [Feat] Bump collector version to `0.106.0`

### v0.87.3 / 2024-07-29
- [Feat] add host entity event preset

### v0.87.2 / 2024-07-26
- [Feat] add kubernetes resource preset

### v0.87.1 / 2024-07-18
- [Feat] add process option for hostmetrics preset.

### v0.87.0 / 2024-07-03
- [Feat] Bump collector version to `0.104.0`

### v0.86.2 / 2024-06-25
- [Fix] Allow configuring max_unmatched_batch_size in multilineConfigs. Default is changed to max_unmatched_batch_size=1.
- [Fix] Fix spanMetrics.spanNameReplacePattern preset does not work

### v0.86.1 / 2024-06-20
- [Fix] Remove logging exporter from the list of default exporters

### v0.86.0 / 2024-06-06
- [Feat] Bump collector version to `0.102.1`

### v0.85.1 / 2024-06-05
- [Fix] add target allocator events and getting secrets permissions.

### v0.85.0 / 2024-05-29
- [Feat] spanMetrics preset allow extraDimensions and apply config to all spanmetrics processors.
- [Feat] Bump collector version to `0.101.0`

### v0.84.1 / 2024-05-28
- [Feat] loadBalancing preset add dns resolver interval and timeout duration options.

### v0.84.0 / 2024-05-06

- [Feat] Bump collector version to `0.100.0`
- [Feat] kubernetesExtraMetrics preset add container cpu throttling metrics.

### v0.83.1 / 2024-05-06

- [Fix] reduceResourceAttributes preset will now work when metadata preset is manually set in processors.

### v0.83.0 / 2024-04-29

- [Feat] Bump collector version to `0.99.0`

### v0.82.1 / 2024-04-17
- [Fix] When routing processor with batch is used make sure routing is last

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
