# Changelog

## OpenTelemetry Collector

### v0.130.7 / 2026-04-09

- [Fix] Fix `podSecurityContext` and `securityContext` indentation when `collectorCRD.generate` is true.

### v0.130.5 / 2026-03-31

- [Feat] Add support for fallback configuration for the Supervisor.

### v0.130.6 / 2026-04-01

- [Feat] Add target allocator `allocationFallbackStrategy`, `probeSelector`, and `probeNamespaceSelector` chart values for Prometheus CR rendering.

### v0.130.5 / 2026-03-31

- [Feat] For `distribution` `standalone` and `macos`, prepend `cx.application.name` and `cx.subsystem.name` to Coralogix exporter `application_name_attributes` and `subsystem_name_attributes` (before `service.namespace` / `service.name`) so presets such as `filelogMulti` and `prometheusMulti` drive Application/Subsystem when set.

### v0.130.4 / 2026-03-16

- [Feat] Use Coralogix' custom Supervised Collector image when `presets.fleetManagement.supervisor` is enabled. For now this custom image includes fallback configuration support (local file and S3).

### v0.130.3 / 2026-03-16

- [Fix] Preserve `telemetry.sdk.*` resource attributes on traces when `reduceResourceAttributes` is enabled in provider-based mode, while continuing to remove them for logs and metrics.

### v0.130.2 / 2026-03-12

- [Fix] Pass `command.extraArgs` to the managed Collector through the supervisor `agent.args` configuration instead of appending them to the `opampsupervisor` container command.

### v0.130.1 / 2026-03-12

- [Feat] Add optional `presets.ebpfProfiler.samplesPerSecond` support that maps to `receivers.profiling.samples_per_second` only when set.

### v0.130.0 / 2026-03-06

- [Feat] Bump OpenTelemetry Collector image to v0.147.0.

### v0.129.9 / 2026-02-26

- [Fix] Ensure `service.profilesSupport` is auto-injected for direct collector runs whenever `profilesCollection` or `ebpfProfiler` presets are enabled, including when fleet management is enabled without supervisor mode, while still avoiding duplicate gates when already provided in `command.extraArgs` or injected by supervisor.

### v0.129.8 / 2026-02-25

- [Fix] Ensure `service.profilesSupport` is automatically enabled for both `profilesCollection` and `ebpfProfiler` presets in both direct collector and supervisor modes, while avoiding duplicate feature-gate arguments when already set via `command.extraArgs`.

### v0.129.7 / 2026-02-25

- [Feat] Extend `ecsAttributesContainerLogs` with `profilesServiceName.enabled` to map profiles `service.name` from ECS resource attributes with fallback order `aws.ecs.task.definition.family` then `aws.ecs.container.name`, wiring the transform only into existing profiles pipelines.

### v0.129.6 / 2026-02-18

- [Fix] AWS resource detection for Deployments/StatefulSets. On EKS clusters where `HttpPutResponseHopLimit=1`, IMDS is not accessible from container pods, causing the EC2/EKS detectors to fail. Deployments/StatefulSets now use the `env` detector with `cloud.provider` and `cloud.platform` attributes injected via `OTEL_RESOURCE_ATTRIBUTES`.
- [Feat] Add top-level `provider` value (aws, gcp, azure, on-prem). When set, overrides inference from distribution. Enables self-managed K8s deployments with distribution="" and explicit provider. Self-managed on AWS uses EC2 detector only (no EKS) for DaemonSets.

### v0.129.5 / 2026-02-15

- [Fix] Use `aws.ecs.cluster.name` instead of `aws.ecs.cluster` for ECS distribution `application_name_attributes` to match the attribute name used by the `awsecscontainermetricsd` receiver.

### v0.129.4 / 2026-02-13

- [Fix] Increase the `presets.loadBalancing.k8s.timeout` default to `1m` so Kubernetes resolver users get a longer resolver timeout by default.

### v0.129.3 / 2026-02-12

- [Fix] Apply stacktrace log recombination only to OTEL Collector stacktraces.

### v0.129.2 / 2026-02-10

- [Fix] Inject `K8S_NODE_NAME` environment variable for all Kubernetes deployments (non-ECS, non-standalone, non-macOS) to support EKS resource detection processors.
- [Fix] Add `eks: node_from_env_var: K8S_NODE_NAME` configuration to `resourcedetection/resource_catalog` processor to fix "node name is empty" error on EKS.
- [Feat] Make `resourcedetection/resource_catalog` processor provider-aware, using only relevant cloud detectors based on distribution setting instead of all cloud providers.

 ### v0.129.1 / 2026-02-10

- [Feat] Add Windows-specific presets: `windowsEventLog` (collects Windows Event Logs), `iisReceiver` (collects IIS metrics), and `iisLogs` (collects IIS access logs with W3C format parsing).
- [Feat] Update `hostMetrics` preset with Windows-specific configuration: exclude `load` scraper, add `paging` scraper, configure `filesystem` to exclude empty mount points, and use `mute_process_all_errors` for process scraper.
- [Feat] Add `standalone-windows` example demonstrating Windows presets for standalone deployments.

### v0.129.0 / 2026-02-05

- [Feat] Bump OpenTelemetry Collector image to v0.145.0.

### v0.128.20 / 2026-02-04

- [Fix] Fix multiline stacktraces parsing for collector logs.

### v0.128.19 / 2026-02-03

- [Fix] Use `collection_interval` for prometheus annotation discovery preset receivers.

### v0.128.18 / 2026-02-03

- [Fix] Remove invalid "gke" detector from resourcedetection/region processor for GCP provider.

### v0.128.17 / 2026-01-23

- [Feat] Add an option to disable the collector metrics Prometheus receiver and transform while keeping telemetry readers enabled.

### v0.128.16 / 2026-01-23

- [Feat] Add prometheus annotation discovery preset for cluster-collector with receiver_creator support for pod and service rules.

### v0.128.15 / 2026-01-22

- [Fix] Use the configured `from` field for profiles k8sattributes service annotations.

### v0.128.14 / 2026-01-22

- [Fix] Fix `deltaToCumulative` preset producing `null` config when no options are set.
- [Fix] Fix `reduceResourceAttributes` preset to only apply custom denylist when no provider is set (backward compatibility mode).

### v0.128.13 / 2026-01-20

- [Fix] Use `instrumentation_scope.name` to detect spanmetrics connector metrics when mapping `otel.status_code` back to `status.code`.

### v0.128.12 / 2026-01-20

- [Feat] Add Azure-specific transform to set `host.name` from `azure.vm.name` when `host.name` is empty, applied to all pipelines including `logs/resource_catalog` when provider is Azure.

### v0.128.11 / 2026-01-16

- [Fix] Ensure the `ecsAttributesContainerLogs` preset adds the ECS attributes processor to the profiles pipeline created by the `ebpfProfiler` preset.
- [Fix] Enable the `ecsAttributesContainerLogs` preset in the `ebpf-profiler` example values.

### v0.128.10 / 2026-01-16

- [Feat] Extend `ecsAttributesContainerLogs` to enrich traces and profiles pipelines when present, and include `container.id` as a supported source for container ID extraction.

### v0.128.9 / 2026-01-15

- [Fix] Gate span metrics status code transforms on `span.name` presence while allowing UNSET mapping when `otel.status_code` is UNSET or unset.

### v0.128.8 / 2026-01-14

- [Feat] Add cloud tags collection for Infra Explore by enabling `ec2.tags` and `azure.tags` in the `resourcedetection/entity` processor.

### v0.128.7 / 2026-01-14

- [Feat] Add Azure cloud support for Infra Explore by mapping `azure.vm.size` to `host.type` in the host entity events pipeline when provider is Azure.

### v0.128.6 / 2026-01-13

- [Fix] Apply `presets.spanMetrics.histogramBuckets` value to `dbMetrics`.

### v0.128.5 / 2026-01-12

- [Feat] Add `systemdReceiver` preset which gathers metrics for locally running systemd units on standalone linux deployments with optional scope and units configuration.

### v0.128.4 / 2026-01-08

– [Fix] Add missing field `service.loadBalancerClass` to support setups with AWS ALB Controller

### v0.128.3 / 2026-01-07

- [Feat] Add an `ebpfProfiler` preset that switches to the otelcol-ebpf-profiler distribution, creates a profiles-only pipeline, and wires the profiling receiver. Allows to configure intervals, thresholds, off-CPU, verbosity, tracers.
- [Feat] Add a `profilesK8sAttributes` preset to enrich profiles with Kubernetes attributes and map service.name from labels/metadata.
- [Feat] Add an `otlpExporter` preset to configure an OTLP endpoint with optional headers, plus pipeline selection.

### v0.128.2 / 2026-01-07

- [Feature] Ensure new behaviors from span metrics connector, defined behind `+connector.spanmetrics.useSecondAsDefaultMetricsUnit`, `+connector.spanmetrics.excludeResourceMetrics`, `+spanmetrics.statusCodeConvention.useOtelPrefix` feature gates don't break backward compatibility.
  - Added `add_resource_attributes: true` to maintain resource attributes in span metrics
  - Added `histogram.unit: ms` to maintain millisecond units for duration metrics
  - Added OTTL transformations to convert new `otel.status_code` back to old `status.code` format with `STATUS_CODE_*` values

### v0.128.1 / 2026-01-06

- [Fix] Remove unused `k8s_observer` extension from `kubernetesExtraMetrics` preset to avoid unnecessary API server load.

### v0.128.0 / 2025-12-30

- [CHORE] Bump Collector to 0.142.0

### v0.127.7 / 2025-12-24

- [Fix] Remove `nop` exporter and receiver from `profiles` pipeline when the `supervisor` and `profilesCollection` presets are enabled. This exporter/receiver does not support profiles yet.

### v0.127.6 / 2025-12-23

- [Feat] Add `dynamicSubsystemName` option to `journaldReceiver` preset to extract subsystem name from systemd unit name or syslog identifier.
- [Fix] Fix `macosSystemLogs` regex pattern to correctly parse multiline log entries.
- [Fix] Fix `macosSystemLogs` dynamic subsystem naming to use `service.name` instead of `cx.subsystem.name` for proper Coralogix exporter compatibility.

### v0.127.5 / 2025-12-23

- [Bug] Apply `resourceDetection` preset to `profiles`.

### v0.127.4 / 2025-12-22

- [Feat] Add `provider` field to `reduceResourceAttributes` and `resourceDetection` presets for targeted cloud provider configuration. When set, only attributes/detectors relevant to the specified provider (aws, azure, gcp, on-prem) and deployment context (`distribution`) are used, reducing config size and avoiding unnecessary statements.
- [Feat] Automatically infer `provider` from `distribution` when not explicitly set (e.g., `eks/fargate` → `aws`, `gke/autopilot` → `gcp`, `aks` → `azure`, `ecs` → `aws`).

### v0.127.3 / 2025-12-22

- [Feature] Add support for custom pod labels on TargetAllocator pods via `targetAllocator.podLabels`.

### v0.127.2 / 2025-12-19

- [Bug] Add missing `node` to `k8s_observer` for `kubernetesApiServerMetrics` preset.

### v0.127.1 / 2025-12-17

- [Fix] Add support for combining `profilesCollection` preset with `fleetManagement` preset.

### v0.127.0 / 2025-12-12

- [CHORE] Bump Collector to 0.141.0

### v0.126.7 / 2025-12-10

- [Feat] Add `deltaToCumulative` preset (disabled by default) to convert metrics from delta temporality to cumulative.

### v0.126.6 / 2025-12-10

- [Feature] Add `service.version` to profile attributes when `profilesCollection` preset is enabled.
-
### v0.126.5 / 2025-12-08

- [Feat] Add `dynamicSubsystemName` option to `macosSystemLogs` preset to control copying unit name to subsystem name.

### v0.126.4 / 2025-12-08

- [Fix] Ensure `logs/resource_catalog` pipeline respects presets for `metadata`, `kubernetesAttributes`, and `resourceDetection`.

### v0.126.3 / 2025-12-05

- [Fix] Fix logic to correctly respect `region.enabled: false` in `resourceDetection` preset.
- [Fix] Align macOS application naming attributes with the standalone distribution by using only `service.name`.

### v0.126.2 / 2025-12-05

- [Feat] Allow disabling the `resourcedetection/region` processor in the `resourceDetection` preset.

### v0.126.1 / 2025-12-05

- [Fix] Align macOS subsystem naming attributes with the standalone distribution by using only `service.name`.

### v0.126.0 / 2025-12-04

- [Feat] Add `kubernetesApiServerMetrics` preset to scrape Kubernetes API server metrics separately from cAdvisor metrics.
- [Breaking] Split `kubernetesExtraMetrics` preset: now only handles cAdvisor metrics scraping. API server scraping moved to `kubernetesApiServerMetrics` preset.

### v0.125.9 / 2025-12-04

- [Feature] Add a `macosSystemLogs` preset to collect `/var/log/system.log` with a preconfigured filelog receiver.

### v0.125.8 / 2025-12-04

- [Fix] Ensure the new `macos` distribution uses a dedicated Coralogix distribution header while preserving ECS-like networking defaults and Linux-only host metrics safeguards.

### v0.125.7 / 2025-12-01

- [Fix] Increase the Supervisor config apply timeout to 30 seconds (previously 5 seconds). This should match the default heartbeat interval.

### v0.125.6 / 2025-11-26

- [Change] Disable database statement sanitization in the span metrics sanitization preset by default.

### v0.125.5 / 2025-11-26

- [Feat] Add `nodeSelector` option to `targetAllocator` preset.

### v0.125.4 / 2025-11-26

- [Change] Narrow default span metrics database sanitization to SQL, Redis, and Memcached statements.

### v0.125.3 / 2025-11-25

- [Fix] Grant EndpointSlice RBAC permissions when enabling the Kubernetes resolver for the loadbalancing exporter.

### v0.125.2 / 2025-11-25

- [Feature] Add `k8s.container.name` to profile attributes when `profilesCollection` preset is enabled.

### v0.125.1 / 2025-11-25

- [Fix] Fix cluster name rendering in Supervisor configuration.

### v0.125.0 / 2025-11-21

- [CHORE] Bump Collector to 0.140.1

### v0.124.6 / 2025-11-19

- [Fix] Add the `health_check` extension to the Supervisor minimal Collector configuration.

### v0.124.5 / 2025-11-16

- [Fix] Remove pipelines that have no exporters after presets are applied so limiting `presets.coralogixExporter.pipelines` to a subset no longer leaves invalid empty pipelines.

### v0.124.4 / 2025-11-13

- [Fix] Use new container image in the Supervisor preset hosted in Coralogix' JFrog instance.

### v0.124.3 / 2025-11-12
- [Fix] Default `deployment.environment.name` to `global.clusterName` when the resource detection preset's `deploymentEnvironmentName` stays empty and preserve it when span metrics' compact pipelines drop resource keys so the cluster identity remains set.

### v0.124.2 / 2025-11-11
- [Fix] Keep compact spanmetrics and database histograms by default by setting `dropHistogram` to `false`.

### v0.124.1 / 2025-11-07
- [Feat] Make the `fleetManagement.supervisor` preset ship a minimal collector config that only wires the OpAMP extension so the supervisor can connect to the Coralogix OpAMP backend.

### v0.4.0 / 2025-11-07
- [Feat] Allow setting custom non-identifying attributes for both supervisor and OpAMP extensions via `fleetManagement.customAttributes` preset.

### v0.123.0 / 2025-11-05
- [CHORE] Revert Collector to 0.137.0

### v0.122.0 / 2025-11-05
- [CHORE] Bump Collector to 0.139.0

### v0.121.17 / 2025-11-03
- [Feat] Allow `filelogMulti` preset receivers to configure multiline log parsing.

### v0.121.16 / 2025-10-29
- [Feat] extend opamp extension and resource catalog exporter to support additional endpoints.

### v0.121.15 / 2025-10-23
- [Feat] Allow `additionalEndpoints` option to `coralogixExporter` preset to add additional Coralogix endpoints.

### v0.121.14 / 2025-10-23
- [Feat] Allow `filelogMulti` receivers to derive Coralogix application and subsystem names from resource attributes after custom operators run.

### v0.121.13 / 2025-10-23
- [Feat] Add `filelogMulti` preset for configuring multiple filelog receivers with Coralogix resource annotations.

### v0.121.12 / 2025-10-22
- [Fix] Emit Coralogix OTLP headers with the `helm-otel-standalone` distribution tag when the standalone distribution is selected.

### v0.121.11 / 2025-10-22
- [Fix] Derive Coralogix application and subsystem names from `service.namespace` and `service.name` when using the standalone distribution.

### v0.121.10 / 2025-10-20
- [Feat] Add `prometheusMulti` preset for scraping multiple Prometheus targets with optional custom labels.
- [Fix] Emit Prometheus multi-target jobs using the provided target name and only apply CX labels when explicitly configured.
- [Chore] Standalone example enables the `prometheusMulti` preset with contrasting target configurations.

### v0.121.9 / 2025-10-20
- [feat] Add`journaldReceiver` preset for systemd journal logs with optional directory, unit, and match filters.

### v0.121.8 / 2025-10-17
- [Feat] Allow conditional resource attribute removals in the `reduceResourceAttributes` preset via denylist entry conditions

### v0.121.7 / 2025-10-16
- [Feat] Add `spanMetricsSanitization` preset to provide span name, URL, and database statement sanitization when span metrics presets are enabled.

### v0.121.6 / 2025-10-15
- [FIX] compact metrics unit name change. compact_duration_count -> compact_duration_ms_count, compact_duration_sum -> compact_duration_ms_sum, db_compact_duration_count -> db_compact_duration_ms_count, compact_duration_sum -> compact_duration_ms_sum

### v0.121.5 / 2025-10-15
- [Feat] Allow configuring resource detection detectors for environment and cloud metadata.

### v0.121.4 / 2025-10-14
- [Feat] Add standalone distribution option that binds Prometheus endpoints to 0.0.0.0 and scrapes host metrics from the root filesystem.

### v0.121.3 / 2025-10-13
- [Feat] Enable compact metrics for span-derived database metrics by default.

### v0.121.2 / 2025-10-08
- [Feat] Enable the compact span metrics preset by default.

### v0.121.1 / 2025-10-08
- [FIX] Route the logs router default path through a continuation stage so extra filelog operators always run and drop the now-redundant export noop stage.

### v0.121.0 / 2025-10-07
- [CHORE] Bump Collector to 0.137.0

### v0.120.5 / 2025-09-30
- [Fix] Exclude EKS detector from resource detection for ECS distributions to prevent startup failures.

### v0.120.4 / 2025-09-29
- [Feat] Add AWS CloudMap resolver support for loadbalancing exporter in ECS-EC2 deployments.

### v0.120.3 / 2025-09-29
- [Feat] Add `resource/metadata` processor to profiles pipeline when `profilesCollection` preset is enabled.

### v0.120.2 / 2025-09-26
- [Fix] Disable the spanMetrics compact preset by default to match pre-v0.120.1 behavior.
- [Fix] Restore spanMetrics example manifests that were removed in v0.120.1.

### v0.120.1 / 2025-09-25
- [Feat] Enable spanMetrics compact metrics preset by default.
- [Chore] Remove spanMetrics presets from bundled examples due to lack of automated testing support.

### v0.120.0 / 2025-09-24
- [CHORE] Bump Collector to 0.136.0

### v0.119.18 2025-09-18
- [Fix] filter k8s node on k8sattributes/profiles processor

### v0.119.17 2025-09-16
- [Feat] add spanmetrics.dbMetrics compact option.

### v0.119.16 / 2025-09-10
- [CHORE] Bump Collector to 0.135.0

### v0.119.15 / 2025-09-05
- [CHORE] Bump Collector to 0.134.1

### v0.119.14 / 2025-09-03
- [Feat] Coralogix exporter: add exporter helper settings (retry_on_failure, sending_queue); flatten values to `presets.coralogixExporter.retryOnFailure` and `sendingQueue`; add example and schema support.

### v0.119.13 / 2025-09-03
- [Feature] Profiling: add `serviceLabels` and `serviceAnnotations` options to `profilesCollection` preset, to allow for custom service name detection.

### v0.119.12 / 2025-09-02
- [Feat] loadBalancing preset: add `pipelines` option to select pipelines (logs, metrics, traces, profiles). Default is ["traces"].

### v0.119.11 / 2025-09-01
- [Fix] Fix quoting issue with EKS Fargate `collectionInterval`.
- [Fix] Fix `otel_annotations` field intendation for `k8sattributes/profiles`.

### v0.119.10 / 2025-09-01
- [Feat] Profiling: improve service name detection by otel conventions.

### v0.119.9 / 2025-08-28
- [Feat] Add support for EKS Fargate.
- [Feat] Added `eks` as detector to `resourcedetection/region` config.

### v0.119.8 / 2025-08-28
- [Feat] ECS logs: optional `multiline` block for filelog receiver with `lineStartPattern`/`lineEndPattern` and `omitPattern`.
- [Chore] ECS example: enable Java stack trace multiline parsing.

### v0.119.7 / 2025-08-25
- [Fix] Correct JSON detection regex in logs collection router to match Docker JSON lines with top-level "log" field.

### v0.119.6 / 2025-08-25
- [Fix] Update OTTL paths to use explicit context prefixes for metrics and spans.

### v0.119.5 / 2025-08-22
- [Feat] Coralogix exporter ECS mode: ECS-specific application/subsystem attributes; logs header set to `ecs-ec2-integration/<version>`.
- [Chore] ECS example: set `presets.metadata.integrationName` to `coralogix-integration-ecs-ec2` and enable ECS mode in Coralogix exporter.
- [Fix] ecs distribution use 0.0.0.0 instead of `MY_POD_IP` in rendered ConfigMap.
- [Feat] Add ECS example.
- [Feat] Add `ecsAttributesContainerLogs` preset to enrich container logs with container_id from `log.file.path`.
- [Feat] Add `awsecscontainermetricsdReceiver` preset to enable `awsecscontainermetricsd` receiver and wire it to metrics pipeline.
- [Feat] Add `ecsLogsCollection` preset to collect ECS container logs from `/hostfs/var/lib/docker/containers/*/*.log` with JSON parsing and recombine.
- [Chore] Switch ECS-specific Coralogix exporter defaults to use `distribution: "ecs"` instead of `presets.coralogixExporter.mode`.

### v0.119.4 / 2025-08-20
- [Fix] Ensure hostEntityEvents preset references k8sattributes processor only when configured.

### v0.119.3 / 2025-08-13
- [Feat] Add Kubernetes service resolver to load balancing preset and required RBAC.

### v0.119.2 / 2025-08-11
- [Fix] Remove rate limiter option from Coralogix exporter preset.

### v0.119.1 / 2025-08-08
- [Feat] Add rate limiter option to Coralogix exporter preset.

### v0.119.0 / 2025-08-08
- [Feat] Update Collector to v0.131.1

### v0.118.29 / 2025-08-07
- [Fix] Fix resource attributes of the Collector's logs in the `filelog` receiver.

### v0.118.28 / 2025-08-07
- [Fix] `profilesCollection` preset correctly adds `coralogix` exporter to `profiles` pipeline.

### v0.118.27 / 2025-08-07
- [Feat] add option to drop compact duration histogram in spanMetrics preset.

### v0.118.26 / 2025-08-05
- [Fix] `headSampling` preset correctly removes `coralogix` exporter from the `traces` pipeline.

### v0.118.25 / 2025-08-05
- [Feat] Add compactMetrics option to spanMetrics preset.

### v0.118.24 / 2025-08-04

- [Feat] Add k8sattributes support for profiles.

### v0.118.23 / 2025-07-28
- [Feat] Add support for profiles in the `reduceResourceAttributes` preset.

### v0.118.22 / 2025-07-28
- [Feat] Add `k8s.container.restart_count` to the `reduceResourceAttributes` preset.

### v0.118.21 / 2025-07-28
- [Fix] Quote IPv6 host in metrics reader when `networkMode: ipv6` is used.

### v0.118.20 / 2025-07-25
- [Fix] Quote IPv6 endpoints when `networkMode: ipv6` is used.
- [Feat] Add example demonstrating IPv6 network mode.

### v0.118.19 / 2025-07-24
- [Fix] Correct transform rule for `otelcol_otelsvc_k8s_pod_deleted_ratio` metric.

### v0.118.18 / 2025-07-24
- [Feat] Remove the attribute `cx.otel_integration.name` through the `reduceResourceAttributes` preset.

### v0.118.17 / 2025-07-24
- [Feat] Add more attribute coming from auto-instrumentation SDKs to the `reduceResourceAttributes` preset.

### v0.118.16 / 2025-07-24
- [Feat] Add additional Prometheus transform rules for collector metrics preset.

### v0.118.15 / 2025-07-23
- [Feat] Fail installation if kubernetesResources preset is enabled in daemonset mode.

### v0.118.14 / 2025-07-23
- [Feat] Set spanMetrics aggregationCardinalityLimit default to 100000.

### v0.118.13 / 2025-07-22
- [Feat] Update Collector to v0.130.1

### v0.118.12 / 2025-07-22
- [Feat] Add `reduceLogAttributes` preset to remove specified log record attributes from collected logs.
- [Fix] Set `error_mode` to `silent` for the transformations of the `reduceResourceAttributes` and `reduceLogAttributes` presets.

### v0.118.11 / 2025-07-21
- [Feat] Add `host.image.id` to the `reduceResourceAttributes` preset.

### v0.118.10 / 2025-07-21
- [Fix] `command.name` override put back in place.

### v0.118.9 / 2025-07-18
- [Fix] `k8sResourceAttributes` preset works correctly when the `fleetManagement` preset is enabled.

### v0.118.8 / 2025-07-18
- [Feat] The `reduceResourceAttributes` preset now also removes attributes from traces and logs pipelines.
- [Feat] The `reduceResourceAttributes` preset now removes a few more attributes.

### v0.118.7 / 2025-07-18
- [Fix] Remove `without_units` from collector metrics preset

### v0.118.6 / 2025-07-18
- [Fix] Skip prometheus receiver from collectorMetrics preset when PodMonitor or ServiceMonitor is enabled

### v0.118.5 / 2025-07-18
- [Fix] Remove extra blank lines when rendering container ports

### v0.118.4 / 2025-07-18
- [Feat] Allow disabling the /var/lib/dbus/machine-id mount via `presets.resourceDetection.dbusMachineId.enabled`

### v0.118.3 / 2025-07-18
- [Feat] Enable `without_units` in collector metrics preset

### v0.118.2 / 2025-07-16
- [Feat] Add transactions preset to group spans into transactions and enable Coralogix transaction processor

### v0.118.1 / 2025-07-16
- [Feat] Add `networkMode` option to configure IPv4 or IPv6 endpoints

### v0.118.0 / 2025-07-16
- [Feat] Update Collector to v0.130.0

### v0.117.5 / 2025-07-16
- [Feat] Update Collector to v0.130.0

### v0.117.4 / 2025-07-16
- [Feat] Allow configuring `aggregation_cardinality_limit` for spanMetrics presets.

## v0.117.3 / 2025-07-10
- [Fix] Remove deprecated match_once key from `spanMetricsMultiConfig` config.

## v0.117.2 / 2025-07-09
- [Fix] Apply `transform/prometheus` rule only for metrics from the Collector itself.

## v0.117.1 / 2025-07-04
- [Feat] Support global `deploymentEnvironmentName` for the resource detection preset.

## v0.117.0 / 2025-07-04
- [Feat] Update Collector to v0.129.1

## v0.116.3 / 2025-07-02
- [Feat] Add new variable `presets.coralogixExporter.pipelines` as an `array[string]` to allow enabling exporter on 2 pipelines at once.

## v0.116.2 / 2025-06-24
- [Fix] Support templating for `presets.resourceDetection.deploymentEnvironmentName`.

## v0.116.1 / 2025-06-24
- [Feat] Allow setting `deployment.environment.name` via `presets.resourceDetection.deploymentEnvironmentName`.

## v0.116.0 / 2025-06-24
- [Feat] Update Collector to v0.128.0

## v0.115.31 / 2025-01-16
- [Feat] Add Helm chart metadata to telemetry resource attributes.
## v0.115.30 / 2025-06-16
- [Fix] Recover metrics `k8s_node_allocatable_cpu__cpu` and `k8s_node_allocatable_memory__By` in `k8sclusterreceiver` on the collector side
## v0.115.29 / 2025-06-13
- [Fix] Fix `command` template helper when using the Supervisor preset.
## v0.115.28 / 2025-06-12
- [Fix] Fix `image` template helper when using the Supervisor preset and when using the Collector CRDs.
## v0.115.27 / 2025-06-11
- [Feat] Add an alpha `supervisor` preset under the `fleetManagement` preset
- [Feat] Certain attributes related to the `fleetManagement` preset are now added
  as non-identifying attributes even when `k8sResourceAttributes` preset is disabled.
## v0.115.26 / 2025-06-09
- [Fix] Add error mode `silent` for managed fields removal in the `kubernetesResources` preset
## v0.115.25 / 2025-06-09
- [Feat] Allow transforming Kubernetes Resources using custom OTTL statements via `presets.kubernetesResources.transformStatements`
## v0.115.24 / 2025-06-09
- [Feat] Allow dropping managed fields from Kubernetes resources via `presets.kubernetesResources.dropManagedFields.enabled`
## v0.115.23 / 2025-05-30
- [Feat] Allow disabling periodic Kubernetes resource collection via `presets.kubernetesResources.periodicCollection.enabled`
## v0.115.22 / 2025-05-30
- [Feat] Allow filtering Kubernetes Resources using custom OTTL statements via `presets.kubernetesResources.filterStatements`
## v0.115.21 / 2025-05-30
- [Fix] Add `KUBE_NODE_NAME` env var when fleet management preset is enabled
## v0.115.20 / 2025-05-30
- [Feat] Make coralogixExporter preset pipeline configurable via `presets.coralogixExporter.pipeline`
## v0.115.19 / 2025-05-30
- [Feat] Make collector metrics preset pipeline configurable via `presets.collectorMetrics.pipeline`
## v0.115.18 / 2025-05-30
- [Feat] Make resource detection preset pipeline configurable via `presets.resourceDetection.pipeline`
## v0.115.17 / 2025-05-30
- [Feat] Extend `k8sResourceAttributes` preset with `service.name` and configurable `cx.agent.type`
## v0.115.16 / 2025-05-30
- [Feat] Add `semconv` preset for `transform/semconv` processor to map `http.request.method` to `http.method`
## v0.115.15 / 2025-05-30
- [Feat] Add `k8sResourceAttributes` preset to populate service telemetry resource attributes with Kubernetes metadata
## v0.115.14 / 2025-05-30
- [Feat] Allow configuring `max_recv_msg_size_mib` for the OTLP receiver via `presets.otlpReceiver.maxRecvMsgSizeMiB` (default 20 MiB)
## v0.115.13 / 2025-05-30
- [Feat] Make extraction of `k8s.pod.uid` and `k8s.pod.start_time` configurable via `presets.kubernetesAttributes.podUid.enabled` and `presets.kubernetesAttributes.podStartTime.enabled`
## v0.115.12 / 2025-05-30
- [Feat] Make Kubernetes attributes node filter configurable via `presets.kubernetesAttributes.nodeFilter.enabled` and automatically inject `K8S_NODE_NAME` env var when enabled
## v0.115.11 / 2025-05-30
- [Feat] Make k8s.node.name resource attribute injection configurable via `presets.resourceDetection.k8sNodeName.enabled`
## v0.115.10 / 2025-05-30
- [Feat] Add pprof preset for profiling
## v0.115.9 / 2025-05-30
- [Feat] Add zpages preset for debugging
## v0.115.8 / 2025-05-29
- [Feat] Add otlp receiver preset to support receiving otlp trace data
- [Breaking] Remove batch processor from default values.yaml
- [Feat] Remove otlp receiver from default values.yaml, enabled otlpReceiver preset instead.

## v0.115.7 / 2025-05-24
- [Feat] Make cluster metrics collection interval configurable through preset
- [Feat] Add optional custom Kubernetes metrics for dashboards via `presets.clusterMetrics.customMetrics`

## v0.115.6 / 2025-05-24
- [Feat] Add default node resource environment variables when `resourceDetection` preset is enabled

## v0.115.5 / 2025-05-24
- [Feat] Add statsdReceiver preset

## v0.115.4 / 2025-05-24
- [Feat] Enhance `kubernetesEvents` preset with `resource/kube-events` and `transform/kube-events` processors
- [Feat] Make cluster name configurable via `presets.kubernetesEvents.clusterName`

## v0.115.3 / 2025-05-24
- [Feat] Add coralogixExporter preset

## v0.115.2 / 2025-05-22
- [Feat] Add batch processor preset

## v0.115.1 / 2025-05-19
- [Update] `kubeletstatsreceiver`: set `collect_all_network_interfaces` on `pods`

## v0.115.0 / 2025-05-19
- [Feat] Update Collector to v0.126.0

## v0.114.5 / 2025-05-19
- [Fix] Fix utilization metric name and unit in `kubeletMetrics` preset to keep the metrics' backward compatibility for dashboards

## v0.114.4 / 2025-05-16
- [Feat] Add resourceDetection preset to add system and environment information to resource attributes

## v0.114.3 / 2025-05-16
- [Feat] Add zipkin receiver preset to support receiving Zipkin-formatted trace data via HTTP on port 9411
- [Breaking] Removes zipkin ports and receiver from default config. Use zipkinReceiver preset instead.

## v0.114.2 / 2025-05-16
- [Feat] Add Jaeger receiver preset to support receiving Jaeger data in all supported protocols (grpc, thrift_http, thrift_compact, thrift_binary)
- [Breaking] Removes jaeger ports and receiver from default config. Use jaegerReceiver preset instead.

## v0.114.1 / 2025-05-15
- [Fix] Add `metricstransformer` to `kubeletMetrics` preset to keep the metrics' backward compatibility for dashboards

## v0.114.0 / 2025-05-15
- [Feat] Update Collector to v0.125.0
- [Fix] Configure `kubeletstatsreceiver` to enable network metrics collection from all available interfaces on Node level

## v0.113.5 / 2025-05-09
- [Fix] Fix collectorMetrics scrape interval setting

## v0.113.4 / 2025-05-09
- [Fix] Fix collectorMetrics preset schema validation

## v0.113.3 / 2025-05-06
- [Fix] Fix collectorMetrics preset scrapeInterval setting.
- [Fix] Fix target allocator namespace.

## v0.113.2 / 2025-05-05
- [Fix] Fix managementState for Collector CRD.
- [Fix] Fix rendering of securityContext and podSecurityContext for Collector CRD.

## v0.113.1 / 2025-05-05
- [Feat] Add collectorMetrics preset to collect collector's own metrics using Prometheus receiver

## v0.113.0 / 2025-04-25
- [Feat] Update Collector to v0.124.1
- [Breaking] We are moving to ghcr image registry instead of dockerhub, as OTel doesn't use dockerhub due to rate limits.

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
