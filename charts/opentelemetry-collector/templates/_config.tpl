{{/*
Default memory limiter configuration for OpenTelemetry Collector based on k8s resource limits.
*/}}
{{- define "opentelemetry-collector.memoryLimiter" -}}
# check_interval is the time between measurements of memory usage.
check_interval: 5s

# By default limit_mib is set to 80% of ".Values.resources.limits.memory"
limit_percentage: 80

# By default spike_limit_mib is set to 25% of ".Values.resources.limits.memory"
spike_limit_percentage: 25
{{- end }}

{{/*
Merge user supplied config into memory limiter config.
*/}}
{{- define "opentelemetry-collector.baseConfig" -}}
{{- $processorsConfig := get .Values.config "processors" }}
{{- if not $processorsConfig.memory_limiter }}
{{-   $_ := set $processorsConfig "memory_limiter" (include "opentelemetry-collector.memoryLimiter" . | fromYaml) }}
{{- end }}

{{- if .Values.useGOMEMLIMIT }}
  {{- if (((.Values.config).service).extensions) }}
    {{- $_ := set .Values.config.service "extensions" (without .Values.config.service.extensions "memory_ballast") }}
  {{- end}}
  {{- $_ := unset (.Values.config.extensions) "memory_ballast" }}
{{- else }}
  {{- $memoryBallastConfig := get .Values.config.extensions "memory_ballast" }}
  {{- if or (not $memoryBallastConfig) (not $memoryBallastConfig.size_in_percentage) }}
  {{-   $_ := set $memoryBallastConfig "size_in_percentage" 40 }}
  {{- end }}
{{- end }}

{{- .Values.config | toYaml }}
{{- end }}

{{/*
Build config file for daemonset OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.daemonsetConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- if .Values.presets.ecsLogsCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyEcsLogsCollectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.logsCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyLogsCollectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- if .Values.presets.logsCollection.reduceLogAttributes.enabled }}
{{- $config = (include "opentelemetry-collector.applyLogsCollectionReduceAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- end }}
{{- if .Values.presets.ecsAttributesContainerLogs.enabled }}
{{- $config = (include "opentelemetry-collector.applyEcsAttributesContainerLogsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.mysql.metrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyMysqlConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.hostMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyHostMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubeletMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubeletMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubernetesAttributes.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubernetesAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.resourceDetection.enabled }}
{{- $config = (include "opentelemetry-collector.applyResourceDetectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubernetesExtraMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubernetesExtraMetrics" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.clusterMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyClusterMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.metadata.enabled }}
{{- $config = (include "opentelemetry-collector.applyMetadataConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.spanMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applySpanMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.targetAllocator.enabled }}
{{- $config = (include "opentelemetry-collector.applyTargetAllocatorConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.spanMetricsMulti.enabled }}
{{- $config = (include "opentelemetry-collector.applySpanMetricsMultiConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubernetesResources.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubernetesResourcesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.hostEntityEvents.enabled }}
{{- $config = (include "opentelemetry-collector.applyHostEntityEventsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.reduceResourceAttributes.enabled }}
{{- $config = (include "opentelemetry-collector.applyReduceResourceAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if and (.Values.presets.fleetManagement.enabled) (not .Values.presets.fleetManagement.supervisor.enabled) }}
{{- $config = (include "opentelemetry-collector.applyFleetManagementConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if and (.Values.presets.k8sResourceAttributes.enabled) }}
{{- $config = (include "opentelemetry-collector.applyK8sResourceAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.semconv.enabled }}
{{- $config = (include "opentelemetry-collector.applySemconvConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.transactions.enabled }}
{{- $config = (include "opentelemetry-collector.applyTransactionsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.extraConfig }}
{{- $config = (include "opentelemetry-collector.applyExtraConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.collectorMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyCollectorMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.jaegerReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyJaegerReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.zipkinReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyZipkinReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.awsecscontainermetricsdReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyAwsecsContainerMetricsdReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.profilesCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyProfilesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- /* Apply load balancing after profiles so profiles pipeline exists when wiring exporters */ -}}
{{- if .Values.presets.loadBalancing.enabled }}
{{- $config = (include "opentelemetry-collector.applyLoadBalancingConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.coralogixExporter.enabled }}
{{- $config = (include "opentelemetry-collector.applyCoralogixExporterConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.otlpReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyOtlpReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.awsecscontainermetricsdReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyAwsecsContainerMetricsdReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.statsdReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyStatsdReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.zpages.enabled }}
{{- $config = (include "opentelemetry-collector.applyZpagesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.pprof.enabled }}
{{- $config = (include "opentelemetry-collector.applyPprofConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.headSampling.enabled }}
{{- $config = (include "opentelemetry-collector.applyHeadSamplingConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if eq .Values.distribution "eks/fargate" }}
{{- $config = (include "opentelemetry-collector.applyEksFargateConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.batch.enabled }}
{{- $config = (include "opentelemetry-collector.applyBatchProcessorConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- $config = (include "opentelemetry-collector.applyBatchProcessorAsLast" (dict "Values" $data "config" $config) | fromYaml) }}
{{- $config = (include "opentelemetry-collector.applyMemoryLimiterProcessorAsFirst" (dict "Values" $data "config" $config) | fromYaml) }}
{{- tpl (toYaml $config) . }}
{{- end }}

{{/*
Build config file for deployment OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.deploymentConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- if eq .Values.distribution "eks/fargate" }}
{{- $config = (include "opentelemetry-collector.applyEksFargateConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.ecsLogsCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyEcsLogsCollectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.logsCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyLogsCollectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- if .Values.presets.logsCollection.reduceLogAttributes.enabled }}
{{- $config = (include "opentelemetry-collector.applyLogsCollectionReduceAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- end }}
{{- if .Values.presets.mysql.metrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyMysqlConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.hostMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyHostMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubeletMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubeletMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubernetesAttributes.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubernetesAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.resourceDetection.enabled }}
{{- $config = (include "opentelemetry-collector.applyResourceDetectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubernetesEvents.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubernetesEventsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.clusterMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyClusterMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubernetesExtraMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubernetesExtraMetrics" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.metadata.enabled }}
{{- $config = (include "opentelemetry-collector.applyMetadataConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.spanMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applySpanMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.loadBalancing.enabled }}
{{- $config = (include "opentelemetry-collector.applyLoadBalancingConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.coralogixExporter.enabled }}
{{- $config = (include "opentelemetry-collector.applyCoralogixExporterConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.targetAllocator.enabled }}
{{- $config = (include "opentelemetry-collector.applyTargetAllocatorConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.spanMetricsMulti.enabled }}
{{- $config = (include "opentelemetry-collector.applySpanMetricsMultiConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.kubernetesResources.enabled }}
{{- $config = (include "opentelemetry-collector.applyKubernetesResourcesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.hostEntityEvents.enabled }}
{{- $config = (include "opentelemetry-collector.applyHostEntityEventsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.reduceResourceAttributes.enabled }}
{{- $config = (include "opentelemetry-collector.applyReduceResourceAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if and (.Values.presets.fleetManagement.enabled) (not .Values.presets.fleetManagement.supervisor.enabled) }}
{{- $config = (include "opentelemetry-collector.applyFleetManagementConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.k8sResourceAttributes.enabled }}
{{- $config = (include "opentelemetry-collector.applyK8sResourceAttributesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.semconv.enabled }}
{{- $config = (include "opentelemetry-collector.applySemconvConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.transactions.enabled }}
{{- $config = (include "opentelemetry-collector.applyTransactionsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.extraConfig }}
{{- $config = (include "opentelemetry-collector.applyExtraConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.headSampling.enabled }}
{{- $config = (include "opentelemetry-collector.applyHeadSamplingConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.collectorMetrics.enabled }}
{{- $config = (include "opentelemetry-collector.applyCollectorMetricsConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.jaegerReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyJaegerReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.zipkinReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyZipkinReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.otlpReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyOtlpReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.statsdReceiver.enabled }}
{{- $config = (include "opentelemetry-collector.applyStatsdReceiverConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.zpages.enabled }}
{{- $config = (include "opentelemetry-collector.applyZpagesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.pprof.enabled }}
{{- $config = (include "opentelemetry-collector.applyPprofConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.batch.enabled }}
{{- $config = (include "opentelemetry-collector.applyBatchProcessorConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- $config = (include "opentelemetry-collector.applyBatchProcessorAsLast" (dict "Values" $data "config" $config) | fromYaml) }}
{{- $config = (include "opentelemetry-collector.applyMemoryLimiterProcessorAsFirst" (dict "Values" $data "config" $config) | fromYaml) }}
{{- tpl (toYaml $config) . }}
{{- end }}

{{- define "opentelemetry-collector.applyBatchProcessorAsLast" -}}
{{- $config := .config }}
{{- if and ($config.service.pipelines.logs) (has "batch" $config.service.pipelines.logs.processors) }}
{{- $_ := set $config.service.pipelines.logs "processors" (without $config.service.pipelines.logs.processors "batch" | uniq)  }}
{{- $_ := set $config.service.pipelines.logs "processors" (append $config.service.pipelines.logs.processors "batch" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (has "batch" $config.service.pipelines.metrics.processors) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (without $config.service.pipelines.metrics.processors "batch" | uniq)  }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "batch" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (has "batch" $config.service.pipelines.traces.processors) }}
{{- $_ := set $config.service.pipelines.traces "processors" (without $config.service.pipelines.traces.processors "batch" | uniq)  }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "batch" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.logs) (has "routing" $config.service.pipelines.logs.processors) }}
{{- $_ := set $config.service.pipelines.logs "processors" (without $config.service.pipelines.logs.processors "routing" | uniq)  }}
{{- $_ := set $config.service.pipelines.logs "processors" (append $config.service.pipelines.logs.processors "routing" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (has "routing" $config.service.pipelines.metrics.processors) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (without $config.service.pipelines.metrics.processors "routing" | uniq)  }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "routing" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (has "routing" $config.service.pipelines.traces.processors) }}
{{- $_ := set $config.service.pipelines.traces "processors" (without $config.service.pipelines.traces.processors "routing" | uniq)  }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "routing" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.profiles) (has "routing" $config.service.pipelines.profiles.processors) }}
{{- $_ := set $config.service.pipelines.profiles "processors" (without $config.service.pipelines.profiles.processors "routing" | uniq)  }}
{{- $_ := set $config.service.pipelines.profiles "processors" (append $config.service.pipelines.profiles.processors "routing" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.applyMemoryLimiterProcessorAsFirst" -}}
{{- $config := .config }}
{{- if and ($config.service.pipelines.logs) (has "memory_limiter" $config.service.pipelines.logs.processors) }}
{{- $_ := set $config.service.pipelines.logs "processors" (without $config.service.pipelines.logs.processors "memory_limiter" | uniq)  }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "memory_limiter" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (has "memory_limiter" $config.service.pipelines.metrics.processors) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (without $config.service.pipelines.metrics.processors "memory_limiter" | uniq)  }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend $config.service.pipelines.metrics.processors "memory_limiter" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (has "memory_limiter" $config.service.pipelines.traces.processors) }}
{{- $_ := set $config.service.pipelines.traces "processors" (without $config.service.pipelines.traces.processors "memory_limiter" | uniq)  }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "memory_limiter" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.profiles) (has "memory_limiter" $config.service.pipelines.profiles.processors) }}
{{- $_ := set $config.service.pipelines.profiles "processors" (without $config.service.pipelines.profiles.processors "memory_limiter" | uniq)  }}
{{- $_ := set $config.service.pipelines.profiles "processors" (prepend $config.service.pipelines.profiles.processors "memory_limiter" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.applyTargetAllocatorConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.targetAllocatorConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "prometheus" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.targetAllocatorConfig" -}}
receivers:
  prometheus:
    config:
      scrape_configs:
      - job_name: opentelemetry-collector
        scrape_interval: 30s
        static_configs:
          - targets:
              - {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "8888" "context" $) | quote }}
    target_allocator:
      endpoint: http://{{ include "opentelemetry-collector.fullname" . }}-targetallocator
      interval: 30s
      collector_id: ${env:MY_POD_NAME}
{{- end }}

{{- define "opentelemetry-collector.applyHostMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.hostMetricsConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "hostmetrics" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.applyExtraConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.extraConfig" .Values | fromYaml) .config }}

{{- range $pipelineType, $pipeline := .Values.Values.extraConfig.service.pipelines }}
  {{- range $componentType, $components := $pipeline }}
    {{- if $config.service.pipelines }}
      {{- if not (hasKey $config.service.pipelines $pipelineType) }}
        {{- fail (printf "Cannot create new pipeline %q with extraConfig please use config.service.pipelines" $pipelineType) }}
      {{- end }}
      {{- $pipeline := index $config.service.pipelines $pipelineType }}
      {{- $existingComponents := index $pipeline $componentType | default list }}
      {{- range $component := $components }}
        {{- if has $component $existingComponents }}
          {{- fail (printf "Pipeline %q already contains component %q of type %q" $pipelineType $component $componentType) }}
        {{- end }}
      {{- end }}
      {{- $_ := set $pipeline $componentType (concat $existingComponents $components) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.extraConfig" -}}
{{- $extraReceivers := .Values.extraConfig.receivers }}
{{- $extraProcessors := .Values.extraConfig.processors }}
{{- $extraExporters := .Values.extraConfig.exporters }}
{{- $extraConnectors := .Values.extraConfig.connectors }}

{{- if $extraProcessors }}
processors:
{{- $extraProcessors | toYaml | nindent 2 }}
{{- end }}

{{- if $extraExporters }}
exporters:
{{- $extraExporters | toYaml | nindent 2 }}
{{- end }}

{{- if $extraReceivers }}
receivers:
{{- $extraReceivers | toYaml | nindent 2 }}
{{- end }}

{{- if $extraConnectors }}
connectors:
{{- $extraConnectors | toYaml | nindent 2 }}
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.hostMetricsConfig" -}}
receivers:
  hostmetrics:
    {{- if not .Values.isWindows }}
    {{- if eq .Values.distribution "ecs" }}
    root_path: /
    {{- else }}
    root_path: /hostfs
    {{- end }}
    {{- end }}
    {{- if .Values.presets.hostMetrics.collectionInterval }}
    collection_interval: "{{ .Values.presets.hostMetrics.collectionInterval }}"
    {{- else }}
    collection_interval: 10s
    {{- end }}
    scrapers:
        cpu:
          metrics:
            system.cpu.utilization:
              enabled: true
        load:
        memory:
          metrics:
            system.memory.utilization:
              enabled: true
        disk:
        filesystem:
          {{- if not .Values.isWindows }}
          exclude_mount_points:
            mount_points:
              - /dev/*
              - /proc/*
              - /sys/*
              - /run/k3s/containerd/*
              - /run/containerd/runc/*
              - /var/lib/docker/*
              - /var/lib/kubelet/*
              - /snap/*
            match_type: regexp
          exclude_fs_types:
            fs_types:
              - autofs
              - binfmt_misc
              - bpf
              - cgroup2
              - configfs
              - debugfs
              - devpts
              - devtmpfs
              - fusectl
              - hugetlbfs
              - iso9660
              - mqueue
              - nsfs
              - overlay
              - proc
              - procfs
              - pstore
              - rpc_pipefs
              - securityfs
              - selinuxfs
              - squashfs
              - sysfs
              - tracefs
            match_type: strict
          {{- end }}
        network:
        {{- if and (.Values.presets.hostMetrics.process.enabled) (not (.Values.isWindows)) }}
        process:
          # mutes "error reading username for process \"pause\" /etc/passwd", errors
          mute_process_user_error: true
          mute_process_exe_error: true
          # fleeting processes cause these errors
          mute_process_name_error: true
          metrics:
            process.cpu.utilization:
              enabled: true
            process.threads:
              enabled: true
            process.memory.utilization:
              enabled: true
        {{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyClusterMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.clusterMetricsConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "k8s_cluster" | uniq)  }}
{{- if .Values.Values.presets.clusterMetrics.customMetrics.enabled }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "metricstransform/k8s-dashboard" | uniq)  }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "transform/k8s-dashboard" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.clusterMetricsConfig" -}}
receivers:
  k8s_cluster:
    allocatable_types_to_report: [cpu, memory]
    {{- if and .Values.presets.clusterMetrics .Values.presets.clusterMetrics.collectionInterval }}
    collection_interval: "{{ .Values.presets.clusterMetrics.collectionInterval }}"
    {{- else }}
    collection_interval: 10s
    {{- end }}
    {{- if and .Values.presets.clusterMetrics .Values.presets.clusterMetrics.customMetrics .Values.presets.clusterMetrics.customMetrics.enabled }}
    resource_attributes:
      k8s.kubelet.version:
        enabled: true
      k8s.pod.qos_class:
        enabled: true
      k8s.container.status.last_terminated_reason:
        enabled: true
    metrics:
      k8s.pod.status_reason:
        enabled: true
    {{- end }}
processors:
  {{- if  .Values.presets.clusterMetrics.customMetrics.enabled }}
  metricstransform/k8s-dashboard:
    transforms:
      - include: k8s.pod.phase
        match_type: strict
        action: insert
        new_name: kube_pod_status_qos_class
      - include: k8s.pod.status_reason
        match_type: strict
        action: insert
        new_name: kube_pod_status_reason
      - include: k8s.node.allocatable_cpu
        match_type: strict
        action: insert
        new_name: kube_node_info
      - include: k8s.container.ready
        match_type: strict
        action: insert
        new_name: k8s.container.status.last_terminated_reason
  transform/k8s-dashboard:
    error_mode: ignore
    metric_statements:
      - context: metric
        statements:
          - set(unit, "1") where name == "k8s.pod.phase"
          - set(unit, "") where name == "kube_node_info"
          - set(unit, "") where name == "k8s.container.status.last_terminated_reason"
      - context: datapoint
        statements:
          - set(value_int, 1) where metric.name == "kube_pod_status_qos_class"
          - set(attributes["qos_class"], resource.attributes["k8s.pod.qos_class"]) where metric.name == "kube_pod_status_qos_class"
          - set(attributes["pod"], resource.attributes["k8s.pod.name"]) where metric.name == "kube_pod_status_reason"
          - set(attributes["reason"], "Evicted") where metric.name == "kube_pod_status_reason" and value_int == 1
          - set(attributes["reason"], "NodeAffinity") where metric.name == "kube_pod_status_reason" and value_int == 2
          - set(attributes["reason"], "NodeLost") where metric.name == "kube_pod_status_reason" and value_int == 3
          - set(attributes["reason"], "Shutdown") where metric.name == "kube_pod_status_reason" and value_int == 4
          - set(attributes["reason"], "UnexpectedAdmissionError") where metric.name == "kube_pod_status_reason" and value_int == 5
          - set(value_int, 0) where metric.name == "kube_pod_status_reason" and value_int == 6
          - set(value_int, 1) where metric.name == "kube_pod_status_reason" and value_int != 0
          - set(value_int, 1) where metric.name == "kube_node_info"
          - set(attributes["kubelet_version"], resource.attributes["k8s.kubelet.version"]) where metric.name == "kube_node_info"
          - set(value_int, 1) where metric.name == "k8s.container.status.last_terminated_reason"
          - set(attributes["reason"], "") where metric.name == "k8s.container.status.last_terminated_reason"
          - set(attributes["reason"], resource.attributes["k8s.container.status.last_terminated_reason"]) where metric.name == "k8s.container.status.last_terminated_reason"
      - context: resource
        statements:
          - delete_key(attributes, "k8s.container.status.last_terminated_reason")
          - delete_key(attributes, "k8s.pod.qos_class")
          - delete_key(attributes, "k8s.kubelet.version")
  {{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyKubeletMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.kubeletMetricsConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "kubeletstats" | uniq)  }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "transform/kubeletstatscpu" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.kubeletMetricsConfig" -}}
receivers:
  kubeletstats:
    {{- if .Values.presets.kubeletMetrics.collectionInterval }}
    collection_interval: "{{ .Values.presets.kubeletMetrics.collectionInterval }}"
    {{- else }}
    collection_interval: 20s
    {{- end }}
    insecure_skip_verify: true
    auth_type: "serviceAccount"
    endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "K8S_NODE_IP" "port" "10250" "context" $) | quote }}
    collect_all_network_interfaces:
      pod: true
      node: true
processors:
  transform/kubeletstatscpu:
    error_mode: ignore
    metric_statements:
      - context: metric
        statements:
          - set(unit, "1") where name == "container.cpu.usage"
          - set(name, "container.cpu.utilization") where name == "container.cpu.usage"
          - set(unit, "1") where name == "k8s.pod.cpu.usage"
          - set(name, "k8s.pod.cpu.utilization") where name == "k8s.pod.cpu.usage"
          - set(unit, "1") where name == "k8s.node.cpu.usage"
          - set(name, "k8s.node.cpu.utilization") where name == "k8s.node.cpu.usage"
{{- end }}

{{- define "opentelemetry-collector.applyLogsCollectionConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.logsCollectionConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append $config.service.pipelines.logs.receivers "filelog" | uniq)  }}
{{- if .Values.Values.presets.logsCollection.storeCheckpoints}}
{{- $_ := set $config.service "extensions" (append $config.service.extensions "file_storage" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.applyProfilesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.profilesCollectionConfig" .Values | fromYaml) .config }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.logsCollectionConfig" -}}
{{- if .Values.presets.logsCollection.storeCheckpoints }}
extensions:
  file_storage:
    directory: /var/lib/otelcol
{{- end }}
receivers:
  filelog:
    {{- if .Values.isWindows }}
    include: ["C:\\var\\log\\pods\\*\\*\\*.log"]
    {{- else }}
    include: [ /var/log/pods/*/*/*.log ]
    {{- end }}
    {{- if .Values.presets.logsCollection.includeCollectorLogs }}
    exclude: []
    {{- else }}
    {{- if .Values.isWindows }}
    exclude: [ "C:\\var\\log\\pods\\{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}*_*\\{{ include "opentelemetry-collector.lowercase_chartname" . }}\\*.log" ]
    {{- else }}
    # Exclude collector container's logs. The file format is /var/log/pods/<namespace_name>_<pod_name>_<pod_uid>/<container_name>/<run_id>.log
    exclude: [ /var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}*_*/{{ include "opentelemetry-collector.lowercase_chartname" . }}/*.log ]
    {{- end }}
    {{- end }}
    start_at: beginning
    retry_on_failure:
        enabled: true
    {{- if .Values.presets.logsCollection.storeCheckpoints}}
    storage: file_storage
    {{- end }}
    force_flush_period: {{ $.Values.presets.logsCollection.forceFlushPeriod }}
    include_file_path: true
    include_file_name: false
    operators:
      # Find out which format is used by kubernetes
      - type: router
        id: get-format
        routes:
          - output: parser-docker
            expr: 'body matches "^\\{"'
          - output: parser-crio
            expr: 'body matches "^[^ Z]+ "'
          - output: parser-containerd
            expr: 'body matches "^[^ Z]+Z"'
      # Parse CRI-O format
      - type: regex_parser
        id: parser-crio
        regex: '^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$'
        timestamp:
          parse_from: attributes.time
          layout_type: gotime
          layout: '2006-01-02T15:04:05.999999999Z07:00'
      - type: recombine
        id: crio-recombine
        output: handle_empty_log
        combine_field: attributes.log
        source_identifier: attributes["log.file.path"]
        is_last_entry: "attributes.logtag == 'F'"
        combine_with: ""
        max_log_size: {{ $.Values.presets.logsCollection.maxRecombineLogSize }}
        max_batch_size: {{ $.Values.presets.logsCollection.maxBatchSize }}
      # Parse CRI-Containerd format
      - type: regex_parser
        id: parser-containerd
        regex: '^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$'
        timestamp:
          parse_from: attributes.time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      - type: recombine
        id: containerd-recombine
        output: handle_empty_log
        combine_field: attributes.log
        source_identifier: attributes["log.file.path"]
        is_last_entry: "attributes.logtag == 'F'"
        combine_with: ""
        max_log_size: {{ $.Values.presets.logsCollection.maxRecombineLogSize }}
        max_batch_size: {{ $.Values.presets.logsCollection.maxBatchSize }}
      # Parse Docker format
      - type: json_parser
        id: parser-docker
        timestamp:
          parse_from: attributes.time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      - type: recombine
        id: docker-recombine
        output: handle_empty_log
        combine_field: attributes.log
        source_identifier: attributes["log.file.path"]
        is_last_entry: attributes.log endsWith "\n"
        combine_with: ""
        max_log_size: {{ $.Values.presets.logsCollection.maxRecombineLogSize }}
        max_batch_size: {{ $.Values.presets.logsCollection.maxBatchSize }}
      - type: add
        id: handle_empty_log
        if: attributes.log == nil
        field: attributes.log
        value: ""
      # Extract metadata from file path
      - type: regex_parser
        {{- if .Values.isWindows }}
        regex: '^C:\\var\\log\\pods\\(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[^\/]+)\\(?P<container_name>[^\._]+)\\(?P<restart_count>\d+)\.log$'
        {{- else }}
        regex: '^.*\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[a-f0-9\-]+)\/(?P<container_name>[^\._]+)\/(?P<restart_count>\d+)\.log$'
        {{- end }}
        parse_from: attributes["log.file.path"]
      # Rename attributes
      - type: move
        from: attributes.stream
        to: attributes["log.iostream"]
      - type: move
        from: attributes.container_name
        to: resource["k8s.container.name"]
      - type: move
        from: attributes.namespace
        to: resource["k8s.namespace.name"]
      - type: move
        from: attributes.pod_name
        to: resource["k8s.pod.name"]
      - type: move
        from: attributes.restart_count
        to: resource["k8s.container.restart_count"]
      - type: move
        from: attributes.uid
        to: resource["k8s.pod.uid"]
      {{- if .Values.presets.logsCollection.multilineConfigs }}
      - type: router
        routes:
        {{- range $.Values.presets.logsCollection.multilineConfigs }}
          - output: {{ include "opentelemetry-collector.newlineKey" . | quote }}
            expr: {{ include "opentelemetry-collector.newlineExpr" . | quote }}
        {{- end }}
        default: clean-up-log-record
      {{- range $.Values.presets.logsCollection.multilineConfigs }}
      - type: recombine
        id: {{ include "opentelemetry-collector.newlineKey" . | quote}}
        output: clean-up-log-record
        combine_field: attributes.log
        source_identifier: attributes["log.file.path"]
        is_first_entry: '(attributes.log) matches {{ .firstEntryRegex | quote }}'
        max_log_size: {{ $.Values.presets.logsCollection.maxRecombineLogSize }}
        max_unmatched_batch_size: {{ $.Values.presets.logsCollection.maxUnmatchedBatchSize }}
        max_batch_size: {{ $.Values.presets.logsCollection.maxBatchSize }}
        {{- if hasKey . "combineWith" }}
        combine_with: {{ .combineWith | quote }}
        {{- end }}
      {{- end }}
      {{- end }}
      # Clean up log body
      - type: move
        id: clean-up-log-record
        from: attributes.log
        to: body
      {{- if .Values.presets.logsCollection.includeCollectorLogs }}
      # Filter out the collector logs that contain logRecord or ResourceLog
      # This is the typical output of debug / logging exporters
      # This prevents the collector from looping over its own logs
      - type: filter
        drop_ratio: 1.0
        expr: '(attributes["log.file.path"] matches "/var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}.*_.*/{{ include "opentelemetry-collector.lowercase_chartname" . }}/.*.log") and ((body contains "logRecord") or (body contains "ResourceLog"))'
      # The operators below should only apply to the logs of our own Collector and are necessary
      # to get the `resource` field from them into the resource attributes that are emitted.
      # This logic should encompass logs of all agents.
      # We do an additional check to ensure the log body has the `resource` field to avoid wasting
      # time and resources on operators that would simply fail.
      - type: router
        routes:
          - output: parse-body
            expr: '(body matches "\"resource\":{.*?},?")'
        default: export
      - type: json_parser
        id: parse-body
        parse_to: attributes["parsed_body_tmp"]
        if: (attributes["log.file.path"] matches "/var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}.*_.*/.*/.*.log")
        on_error: send_quiet
      - type: regex_replace
        field: body
        regex: \"resource\":{.*?},?
        replace_with: ""
        if: (attributes["log.file.path"] matches "/var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}.*_.*/.*/.*.log")
        on_error: send_quiet
      - type: move
        from: attributes["parsed_body_tmp"]["resource"]
        to: resource["attributes_tmp"]
        if: (attributes["log.file.path"] matches "/var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}.*_.*/.*/.*.log")
        on_error: send_quiet
      - type: remove
        field: attributes["parsed_body_tmp"]
        if: (attributes["log.file.path"] matches "/var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}.*_.*/.*/.*.log")
        on_error: send_quiet
      - type: flatten
        id: flatten-resource
        if: (attributes["log.file.path"] matches "/var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}.*_.*/.*/.*.log")
        field: resource["attributes_tmp"]
        on_error: send_quiet
      {{- end }}
      {{- if .Values.presets.logsCollection.extraFilelogOperators }}
      {{- .Values.presets.logsCollection.extraFilelogOperators | toYaml | nindent 6 }}
      {{- end }}
      # This noop operator is a helper to quickly route an entry to be exported.
      # It must always be the last operator in the receiver.
      - type: noop
        id: export
{{- end }}

{{- define "opentelemetry-collector.applyLogsCollectionReduceAttributesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.logsCollectionReduceAttributesConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.logs "processors" (append $config.service.pipelines.logs.processors "transform/reduce_log_attributes" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.logsCollectionReduceAttributesConfig" -}}
processors:
  transform/reduce_log_attributes:
    error_mode: silent
    log_statements:
      - context: log
        statements:
{{- range .Values.presets.logsCollection.reduceLogAttributes.denylist }}
          - delete_key(attributes, "{{ . }}")
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.profilesCollectionConfig" -}}
processors:
  transform/profiles:
    profile_statements:
    # prioritized by
    # https://opentelemetry.io/docs/specs/semconv/non-normative/k8s-attributes/#how-servicename-should-be-calculated
     {{- range $index, $serviceAnnotation := .Values.presets.profilesCollection.serviceAnnotations }}
      - set(resource.attributes["service.name"], resource.attributes[{{ $serviceAnnotation.tag_name | quote }}])
        where resource.attributes["service.name"] == nil and resource.attributes[{{ $serviceAnnotation.tag_name | quote }}] != nil

    {{- end }}
    {{- range $index, $serviceLabel := .Values.presets.profilesCollection.serviceLabels }}
      - set(resource.attributes["service.name"], resource.attributes[{{ $serviceLabel.tag_name  | quote }}])
        where resource.attributes["service.name"] == nil and resource.attributes[{{ $serviceLabel.tag_name | quote }}] != nil

    {{- end }}
      - set(resource.attributes["service.name"], resource.attributes["k8s.label.instance"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.label.instance"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.label.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.label.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.deployment.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.deployment.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.replicaset.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.replicaset.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.statefulset.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.statefulset.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.daemonset.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.daemonset.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.cronjob.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.cronjob.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.job.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.job.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.pod.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.pod.name"] != nil

      - set(resource.attributes["service.name"], resource.attributes["k8s.container.name"])
        where resource.attributes["service.name"] == nil and resource.attributes["k8s.container.name"] != nil

  k8sattributes/profiles:
    {{- if or (eq .Values.mode "daemonset") .Values.presets.kubernetesAttributes.nodeFilter.enabled }}
    filter:
      node_from_env_var: K8S_NODE_NAME
    {{- end }}
    extract:
      metadata:
        - k8s.namespace.name
        - k8s.replicaset.name
        - k8s.statefulset.name
        - k8s.daemonset.name
        - k8s.deployment.name
        - k8s.cronjob.name
        - k8s.job.name
        - k8s.pod.name
        - k8s.node.name
        - container.id
      labels:
        - tag_name: k8s.label.name
          key: app.kubernetes.io/name
          from: pod
        - tag_name: k8s.label.instance
          key: app.kubernetes.io/instance
          from: pod
      {{- range $index, $serviceLabel := .Values.presets.profilesCollection.serviceLabels }}
        - tag_name: {{ $serviceLabel.tag_name | quote }}
          key: {{ $serviceLabel.key | quote }}
          from: {{ $serviceLabel.from | default "pod" | quote }}
      {{- end }}

      {{- if .Values.presets.profilesCollection.serviceAnnotations }}
      annotations:
          {{- range $index, $serviceAnnotation := .Values.presets.profilesCollection.serviceAnnotations }}
        - tag_name: {{ $serviceAnnotation.tag_name | quote }}
          key: {{ $serviceAnnotation.key | quote }}
          from:  {{ $serviceAnnotation.key | default "pod" | quote }}
          {{- end }}
      {{- end }}
      otel_annotations: true

    passthrough: false
    pod_association:
      - sources:
          - from: resource_attribute
            name: container.id

service:
  pipelines:
    profiles:
      receivers: []
      processors:
        - memory_limiter
        - k8sattributes/profiles
        - resource/metadata
        - transform/profiles
      exporters: []
{{- end }}

{{- define "opentelemetry-collector.applyKubernetesExtraMetrics" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.kubernetesExtraMetricsConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "prometheus/k8s_extra_metrics" | uniq)  }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "filter/k8s_extra_metrics" | uniq)  }}
{{- $_ := set $config.service "extensions" (append $config.service.extensions "k8s_observer" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.kubernetesExtraMetricsConfig" -}}
extensions:
  k8s_observer:
    auth_type: serviceAccount
    observe_pods: true
receivers:
  prometheus/k8s_extra_metrics:
    config:
      scrape_configs:
      {{- if .Values.presets.kubernetesExtraMetrics.perNode }}
      - job_name: kubernetes-cadvisor
        honor_timestamps: true
        metrics_path: /metrics/cadvisor
        scheme: https
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        static_configs:
          - targets: [ {{ include "opentelemetry-collector.envEndpoint" (dict "env" "K8S_NODE_IP" "port" "10250" "context" $) | quote }} ]
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
      {{- else }}
      - job_name: kubernetes-apiserver
        honor_timestamps: true
        scheme: https
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
        kubernetes_sd_configs:
        - role: endpoints
        relabel_configs:
          - source_labels:
              [
                __meta_kubernetes_namespace,
                __meta_kubernetes_service_name,
                __meta_kubernetes_endpoint_port_name,
              ]
            action: keep
            regex: default;kubernetes;https
      - job_name: kubernetes-cadvisor
        honor_timestamps: true
        metrics_path: /metrics/cadvisor
        scheme: https
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          insecure_skip_verify: true
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
      {{- end }}
processors:
  filter/k8s_extra_metrics:
    metrics:
      metric:
        {{- if .Values.presets.kubernetesExtraMetrics.scrapeAll }}
        - 'resource.attributes["service.name"] == "kubernetes-apiserver" and name != "kubernetes_build_info"'
        {{- else }}
        - 'resource.attributes["service.name"] == "kubernetes-apiserver" and name != "kubernetes_build_info"'
        - 'resource.attributes["service.name"] == "kubernetes-cadvisor" and
          (name != "container_fs_writes_total" and name != "container_fs_reads_total" and
          name != "container_fs_writes_bytes_total" and name != "container_fs_reads_bytes_total" and
          name != "container_fs_usage_bytes" and name != "container_cpu_cfs_throttled_periods_total" and
          name != "container_cpu_cfs_periods_total")'
        {{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyMysqlConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.mysqlConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "receiver_creator/mysql" | uniq)  }}
{{- $_ := set $config.service "extensions" (append $config.service.extensions "k8s_observer" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.mysqlConfig" -}}
{{- $instances := deepCopy .Values.presets.mysql.metrics.instances }}
{{- range $key, $instance := $instances }}
extensions:
  k8s_observer:
    auth_type: serviceAccount
    node: ${env:K8S_NODE_NAME}
    observe_pods: true
receivers:
  receiver_creator/mysql:
    watch_observers: [k8s_observer]
    receivers:
      mysql:
        rule: type == "port" && port == {{ $instance.port | default 3306 }} {{- range $name, $value := $instance.labelSelectors }} && pod.labels["{{ $name }}"] == "{{ $value }}" {{- end }}
        config:
          username: {{ $instance.username }}
          password: {{ $instance.password }}
          {{- if $instance.collectionInterval }}
          collection_interval: "{{ $instance.collectionInterval }}"
          {{- else }}
          collection_interval: 10s
          {{- end }}
          statement_events:
            digest_text_limit: 120
            time_limit: 24h
            limit: 250
          metrics:
            mysql.query.count:
              enabled: true
            mysql.query.slow.count:
              enabled: true
            mysql.joins:
              enabled: true
            mysql.sorts:
              enabled: true
            mysql.connection.errors:
              enabled: true
            mysql.commands:
              enabled: true
            mysql.client.network.io:
              enabled: true
            mysql.table_open_cache:
              enabled: true

{{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyKubernetesAttributesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.kubernetesAttributesConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.logs) (not (has "transform/k8s_attributes" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (append $config.service.pipelines.logs.processors "transform/k8s_attributes" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.logs) (not (has "k8sattributes" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "k8sattributes" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "transform/k8s_attributes" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "transform/k8s_attributes" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "k8sattributes" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend $config.service.pipelines.metrics.processors "k8sattributes" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (not (has "transform/k8s_attributes" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "transform/k8s_attributes" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (not (has "k8sattributes" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "k8sattributes" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.applyMetadataConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.metadataConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.logs) (not (has "resource/metadata" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "resource/metadata" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "resource/metadata" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend $config.service.pipelines.metrics.processors "resource/metadata" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (not (has "resource/metadata" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "resource/metadata" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.profiles) (not (has "resource/metadata" $config.service.pipelines.profiles.processors)) }}
{{- $_ := set $config.service.pipelines.profiles "processors" (prepend $config.service.pipelines.profiles.processors "resource/metadata" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.metadataConfig" -}}
processors:
  resource/metadata:
    attributes:
      {{- if .Values.presets.metadata.clusterName }}
      - key: k8s.cluster.name
        value: "{{ .Values.presets.metadata.clusterName }}"
        action: upsert
      {{- end }}
      {{- if .Values.presets.metadata.integrationName }}
      - key: cx.otel_integration.name
        value: "{{ .Values.presets.metadata.integrationName }}"
        action: upsert
      {{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyReduceResourceAttributesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.reduceResourceAttributesConfig" .Values | fromYaml) .config }}
{{- $pipelines := .Values.Values.presets.reduceResourceAttributes.pipelines }}
{{- if or (has "metrics" $pipelines) (has "all" $pipelines) }}
  {{- if and ($config.service.pipelines.metrics) (not (has "transform/reduce" $config.service.pipelines.metrics.processors)) }}
  {{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "transform/reduce" | uniq)  }}
  {{- end }}
{{- end }}
{{- if or (has "traces" $pipelines) (has "all" $pipelines) }}
  {{- if and ($config.service.pipelines.traces) (not (has "transform/reduce" $config.service.pipelines.traces.processors)) }}
  {{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "transform/reduce" | uniq)  }}
  {{- end }}
{{- end }}
{{- if or (has "logs" $pipelines) (has "all" $pipelines) }}
  {{- if and ($config.service.pipelines.logs) (not (has "transform/reduce" $config.service.pipelines.logs.processors)) }}
  {{- $_ := set $config.service.pipelines.logs "processors" (append $config.service.pipelines.logs.processors "transform/reduce" | uniq)  }}
  {{- end }}
{{- end }}
{{- if or (has "profiles" $pipelines) (has "all" $pipelines) }}
  {{- if and ($config.service.pipelines.profiles) (not (has "transform/reduce" $config.service.pipelines.profiles.processors)) }}
  {{- $_ := set $config.service.pipelines.profiles "processors" (append $config.service.pipelines.profiles.processors "transform/reduce" | uniq)  }}
  {{- end }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.reduceResourceAttributesConfig" -}}
{{- $pipelines := .Values.presets.reduceResourceAttributes.pipelines }}
processors:
  transform/reduce:
    error_mode: silent
{{- if or (has "metrics" $pipelines) (has "all" $pipelines) }}
    metric_statements:
      - context: resource
        statements:
        {{- range $index, $pattern := .Values.presets.reduceResourceAttributes.denylist.metrics }}
        - delete_key(attributes, "{{ $pattern }}")
        {{- end }}
{{- end }}
{{- if or (has "traces" $pipelines) (has "all" $pipelines) }}
    trace_statements:
      - context: resource
        statements:
        {{- range $index, $pattern := .Values.presets.reduceResourceAttributes.denylist.traces }}
        - delete_key(attributes, "{{ $pattern }}")
        {{- end }}
{{- end }}
{{- if or (has "logs" $pipelines) (has "all" $pipelines) }}
    log_statements:
      - context: resource
        statements:
        {{- range $index, $pattern := .Values.presets.reduceResourceAttributes.denylist.logs }}
        - delete_key(attributes, "{{ $pattern }}")
        {{- end }}
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.applySemconvConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.semconvConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.traces) (not (has "transform/semconv" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "transform/semconv" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.semconvConfig" -}}
processors:
  transform/semconv:
    error_mode: ignore
    trace_statements:
      - context: span
        statements:
          - set(attributes["http.method"], attributes["http.request.method"]) where attributes["http.request.method"] != nil
{{- end }}

{{- define "opentelemetry-collector.applyFleetManagementConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.fleetManagementConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.extensions) (not (has "opamp" $config.service.extensions)) }}
{{- $_ := set $config.service "extensions" (append $config.service.extensions "opamp" | uniq) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.fleetManagementConfig" -}}
extensions:
    opamp:
      server:
        http:
          endpoint: "https://ingress.{{.Values.global.domain}}/opamp/v1"
          polling_interval: 2m
          headers:
            Authorization: "Bearer ${env:CORALOGIX_PRIVATE_KEY}"
      agent_description:
        include_resource_attributes: true
        non_identifying_attributes:
        {{- include "opentelemetry-collector.fleetAttributes" . | nindent 10 -}}
        {{- include "opentelemetry-collector.chartMetadataAttributes" . | nindent 10 -}}
{{- end }}

{{- define "opentelemetry-collector.applyK8sResourceAttributesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.k8sResourceAttributesConfig" .Values | fromYaml) .config }}
{{- $config | toYaml }}
{{- end -}}

{{- define "opentelemetry-collector.k8sResourceAttributesConfig" -}}
service:
  telemetry:
    resource:
      service.name: "opentelemetry-collector"
{{- include "opentelemetry-collector.k8sResourceAttributes" . | nindent 6 -}}
{{- end -}}

{{- define "opentelemetry-collector.k8sResourceAttributes" -}}
{{- $root := $ -}}
{{- if eq $root.Values.mode "daemonset" -}}
k8s.daemonset.name: "{{ include "opentelemetry-collector.fullname" . }}"
{{- else if eq $root.Values.mode "statefulset" -}}
k8s.statefulset.name: "{{ include "opentelemetry-collector.fullname" . }}"
{{- else -}}
k8s.deployment.name: "{{ include "opentelemetry-collector.fullname" . }}"
{{- end }}
k8s.namespace.name: "{{ .Release.Namespace }}"
k8s.node.name: ${env:KUBE_NODE_NAME}
k8s.pod.name: ${env:KUBE_POD_NAME}
{{- end -}}

{{- define "opentelemetry-collector.fleetAttributes" -}}
{{- if or .Values.presets.fleetManagement.agentType .Values.presets.k8sResourceAttributes.agentType }}
cx.agent.type: "{{.Values.presets.fleetManagement.agentType | default .Values.presets.k8sResourceAttributes.agentType}}"
{{- end }}
{{- if .Values.presets.fleetManagement.clusterName }}
cx.cluster.name: "{{ .Values.presets.fleetManagement.clusterName }}"
{{- end }}
{{- if .Values.presets.fleetManagement.integrationID }}
cx.integrationID: "{{ .Values.presets.fleetManagement.integrationID }}"
{{- end }}
{{- end -}}

{{- define "opentelemetry-collector.applySpanMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.spanMetricsConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.traces) (not (has "spanmetrics" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "spanmetrics" | uniq)  }}
{{- end }}
{{- if .Values.Values.presets.spanMetrics.dbMetrics.enabled}}
{{- if and ($config.service.pipelines.traces) (not (has "forward/db" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "forward/db" | uniq)  }}
{{- end }}
{{- end }}
{{- if .Values.Values.presets.spanMetrics.compactMetrics.enabled}}
{{- if and ($config.service.pipelines.traces) (not (has "forward/compact" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "forward/compact" | uniq)  }}
{{- end }}
{{- end }}
{{- if .Values.Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled}}
{{- if and ($config.service.pipelines.traces) (not (has "forward/db_compact" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "forward/db_compact" | uniq)  }}
{{- end }}
{{- end }}
{{- if .Values.Values.presets.spanMetrics.transformStatements}}
{{- if and ($config.service.pipelines.traces) (not (has "transform/spanmetrics" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "transform/spanmetrics" | uniq)  }}
{{- end }}
{{- end }}
{{- if .Values.Values.presets.spanMetrics.spanNameReplacePattern}}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "transform/span_name" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "spanmetrics" $config.service.pipelines.metrics.receivers)) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "spanmetrics" | uniq)  }}
{{- end }}
{{- if .Values.Values.presets.spanMetrics.dbMetrics.enabled}}
{{- if and ($config.service.pipelines.metrics) (not (has "spanmetrics/db" $config.service.pipelines.metrics.receivers)) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "spanmetrics/db" | uniq)  }}
{{- end }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.spanMetrics.extraDimensions" }}
{{- if .Values.presets.spanMetrics.extraDimensions }}
{{- .Values.presets.spanMetrics.extraDimensions | toYaml }}
{{- end }}
{{- if .Values.presets.spanMetrics.errorTracking.enabled }}
- name: http.response.status_code
- name: rpc.grpc.status_code
{{- end }}
{{- if .Values.presets.spanMetrics.serviceVersion.enabled }}
- name: service.version
{{- end }}
{{- end}}

{{- define "opentelemetry-collector.spanMetricsConfig" -}}
connectors:
  spanmetrics:
{{- if .Values.presets.spanMetrics.namespace }}
    namespace: "{{ .Values.presets.spanMetrics.namespace }}"
{{- else }}
    namespace: ""
{{- end }}
    aggregation_cardinality_limit: {{ .Values.presets.spanMetrics.aggregationCardinalityLimit }}
{{- if .Values.presets.spanMetrics.histogramBuckets }}
    histogram:
      explicit:
        buckets: {{ .Values.presets.spanMetrics.histogramBuckets | toYaml | nindent 12 }}
{{- end }}
{{- $extraDimensions := include "opentelemetry-collector.spanMetrics.extraDimensions" . }}
{{- if and $extraDimensions (gt (len $extraDimensions) 0) }}
    dimensions:
{{- $extraDimensions |  nindent 10 }}
{{- end }}
{{- if .Values.presets.spanMetrics.collectionInterval }}
    metrics_flush_interval: "{{ .Values.presets.spanMetrics.collectionInterval }}"
{{- else }}
    metrics_flush_interval: 15s
{{- end }}
{{- if .Values.presets.spanMetrics.metricsExpiration }}
    metrics_expiration: "{{ .Values.presets.spanMetrics.metricsExpiration }}"
{{- else }}
    metrics_expiration: 0
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.enabled }}
  spanmetrics/db:
    namespace: "db"
    aggregation_cardinality_limit: {{ .Values.presets.spanMetrics.aggregationCardinalityLimit }}
    histogram:
      explicit:
        buckets: [100us, 1ms, 2ms, 2.5ms, 4ms, 6ms, 10ms, 100ms, 250ms]
    dimensions:
      - name: db.namespace
      - name: db.operation.name
      - name: db.collection.name
      - name: db.system
      {{- if .Values.presets.spanMetrics.dbMetrics.serviceVersion.enabled }}
      - name: service.version
      {{- end }}
      {{- if .Values.presets.spanMetrics.dbMetrics.extraDimensions }}
      {{- .Values.presets.spanMetrics.dbMetrics.extraDimensions | toYaml | nindent 6 }}
      {{- end }}
{{- if .Values.presets.spanMetrics.metricsExpiration }}
    metrics_expiration: "{{ .Values.presets.spanMetrics.metricsExpiration }}"
{{- else }}
    metrics_expiration: 0
{{- end }}
{{- if .Values.presets.spanMetrics.collectionInterval }}
    metrics_flush_interval: "{{ .Values.presets.spanMetrics.collectionInterval }}"
{{- else }}
    metrics_flush_interval: 15s
{{- end }}
  forward/db: {}
{{- end }}
{{- if .Values.presets.spanMetrics.compactMetrics.enabled }}
  forward/compact: {}
  spanmetrics/compact:
    aggregation_cardinality_limit: {{ .Values.presets.spanMetrics.aggregationCardinalityLimit }}
    exclude_dimensions:
    - span.name
{{- if .Values.presets.spanMetrics.histogramBuckets }}
    histogram:
      explicit:
        buckets: {{ .Values.presets.spanMetrics.histogramBuckets | toYaml | nindent 12 }}
{{- end }}
{{- if .Values.presets.spanMetrics.metricsExpiration }}
    metrics_expiration: "{{ .Values.presets.spanMetrics.metricsExpiration }}"
{{- else }}
    metrics_expiration: 0
{{- end }}
{{- if .Values.presets.spanMetrics.collectionInterval }}
    metrics_flush_interval: "{{ .Values.presets.spanMetrics.collectionInterval }}"
{{- else }}
    metrics_flush_interval: 15s
{{- end }}
    namespace: compact
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled }}
  forward/db_compact: {}
  spanmetrics/db_compact:
    aggregation_cardinality_limit: {{ .Values.presets.spanMetrics.aggregationCardinalityLimit }}
    dimensions:
      - name: db.namespace
      - name: db.system
    exclude_dimensions:
    - span.name
    - span.kind
{{- if .Values.presets.spanMetrics.histogramBuckets }}
    histogram:
      explicit:
        buckets: {{ .Values.presets.spanMetrics.histogramBuckets | toYaml | nindent 12 }}
{{- end }}
{{- if .Values.presets.spanMetrics.metricsExpiration }}
    metrics_expiration: "{{ .Values.presets.spanMetrics.metricsExpiration }}"
{{- else }}
    metrics_expiration: 0
{{- end }}
{{- if .Values.presets.spanMetrics.collectionInterval }}
    metrics_flush_interval: "{{ .Values.presets.spanMetrics.collectionInterval }}"
{{- else }}
    metrics_flush_interval: 15s
{{- end }}
    namespace: db_compact
{{- end }}
{{- if or (.Values.presets.spanMetrics.spanNameReplacePattern) (.Values.presets.spanMetrics.dbMetrics.enabled) (.Values.presets.spanMetrics.transformStatements) (.Values.presets.spanMetrics.compactMetrics.enabled) (.Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled) }}
processors:
{{- end}}
{{- if .Values.presets.spanMetrics.spanNameReplacePattern }}
  transform/span_name:
    trace_statements:
      - context: span
        statements:
        {{- range $index, $pattern := .Values.presets.spanMetrics.spanNameReplacePattern }}
        - replace_pattern(span.name, "{{ $pattern.regex }}", "{{ $pattern.replacement }}")
        {{- end}}
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.enabled }}
  filter/db_spanmetrics:
    traces:
      span:
        - 'attributes["db.system"] == nil'
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled }}
  filter/db_compact_spanmetrics:
    traces:
      span:
        - 'kind != SPAN_KIND_CLIENT or attributes["db.namespace"] == nil or attributes["db.system"] == nil'
{{- end }}
{{- if .Values.presets.spanMetrics.transformStatements }}
  transform/spanmetrics:
    error_mode: silent
    trace_statements:
      - context: span
        statements:
        {{- range $index, $pattern := .Values.presets.spanMetrics.transformStatements }}
        - {{ $pattern }}
        {{- end}}
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.transformStatements }}
  transform/db:
    error_mode: silent
    trace_statements:
      - context: span
        statements:
        {{- range $index, $pattern := .Values.presets.spanMetrics.dbMetrics.transformStatements }}
        - {{ $pattern }}
        {{- end}}
{{- end }}
{{- if .Values.presets.spanMetrics.compactMetrics.enabled }}
  transform/compact:
    trace_statements:
      - context: resource
        statements:
          - keep_keys(attributes, ["service.name", "k8s.cluster.name", "host.name"])
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled }}
  transform/db_compact:
    trace_statements:
      - context: resource
        statements:
          - keep_keys(attributes, ["service.name", "k8s.cluster.name", "host.name"])
      - context: span
        statements:
          - keep_keys(attributes, ["db.namespace", "db.system"])
{{- end }}
{{- if and (.Values.presets.spanMetrics.compactMetrics.enabled) (.Values.presets.spanMetrics.compactMetrics.dropHistogram) }}
  transform/compact_histogram:
    metric_statements:
      - context: metric
        statements:
          - extract_sum_metric(false, ".sum") where name == "compact.duration"
          - extract_count_metric(false, ".count") where name == "compact.duration"
          - set(unit, "") where name == "compact.duration.sum"
          - set(unit, "") where name == "compact.duration.count"
  filter/drop_histogram:
    metrics:
      metric:
        - 'name == "compact.duration"'
{{- end }}
{{- if and (.Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled) (.Values.presets.spanMetrics.dbMetrics.compactMetrics.dropHistogram) }}
  transform/db_compact_histogram:
    metric_statements:
      - context: metric
        statements:
          - extract_sum_metric(false, ".sum") where name == "db_compact.duration"
          - extract_count_metric(false, ".count") where name == "db_compact.duration"
          - set(unit, "") where name == "db_compact.duration.sum"
          - set(unit, "") where name == "db_compact.duration.count"
  filter/drop_db_compact_histogram:
    metrics:
      metric:
        - 'name == "db_compact.duration"'
{{- end }}
{{- if or (.Values.presets.spanMetrics.dbMetrics.enabled) (.Values.presets.spanMetrics.compactMetrics.enabled) (.Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled) }}
service:
  pipelines:
{{- if .Values.presets.spanMetrics.dbMetrics.enabled }}
    traces/db:
      exporters:
      - spanmetrics/db
      processors:
      - filter/db_spanmetrics
      {{- if .Values.presets.spanMetrics.dbMetrics.transformStatements }}
      - transform/db
      {{- end }}
      - batch
      receivers:
      - forward/db
{{- end }}
{{- if .Values.presets.spanMetrics.compactMetrics.enabled }}
    traces/compact:
      exporters:
      - spanmetrics/compact
      processors:
      - transform/compact
      - batch
      receivers:
      - forward/compact
    metrics/compact:
      receivers:
      - spanmetrics/compact
      processors:
      - memory_limiter
      {{- if .Values.presets.spanMetrics.compactMetrics.dropHistogram }}
      - transform/compact_histogram
      - filter/drop_histogram
      {{- end }}
      - batch
      exporters:
      - coralogix
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.compactMetrics.enabled }}
    traces/db_compact:
      exporters:
      - spanmetrics/db_compact
      processors:
      - filter/db_compact_spanmetrics
      - transform/db_compact
      - batch
      receivers:
      - forward/db_compact
    metrics/db_compact:
      receivers:
      - spanmetrics/db_compact
      processors:
      - memory_limiter
      {{- if .Values.presets.spanMetrics.dbMetrics.compactMetrics.dropHistogram }}
      - transform/db_compact_histogram
      - filter/drop_db_compact_histogram
      {{- end }}
      - batch
      exporters:
      - coralogix
{{- end }}
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.spanMetricsMulti.extraDimensions" }}
{{- if .Values.presets.spanMetricsMulti.extraDimensions }}
{{- .Values.presets.spanMetricsMulti.extraDimensions | toYaml }}
{{- end }}
{{- if .Values.presets.spanMetrics.errorTracking.enabled }}
- name: http.response.status_code
- name: rpc.grpc.status_code
{{- end }}
{{- end}}

{{- define "opentelemetry-collector.applySpanMetricsMultiConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.spanMetricsMultiConfig" .Values | fromYaml) .config }}
{{- $tracesPipeline := deepCopy $config.service.pipelines.traces }}
{{- $_ := set $tracesPipeline "processors" (list "batch") }}
{{- $_ := set $tracesPipeline "receivers" (list "routing") }}
{{- range $index, $cfg := .Values.Values.presets.spanMetricsMulti.configs }}
{{- $pipeline := deepCopy $tracesPipeline}}
{{- $pipelineKey := (printf "traces/%d" $index) }}
{{- $_ := set $pipeline "exporters" (append $pipeline.exporters (printf "spanmetrics/%d" $index) ) }}
{{- $_ := merge $config.service.pipelines (dict $pipelineKey $pipeline )  }}
{{- end }}
{{- $pipeline := deepCopy $tracesPipeline}}
{{- $_ := set $pipeline "exporters" (append $pipeline.exporters "spanmetrics/default" ) }}
{{- $_ := merge $config.service.pipelines (dict "traces/default" $pipeline )  }}
{{- if $config.service.pipelines.traces }}
{{- $_ := set $config.service.pipelines.traces "exporters" (list "routing") }}
{{- end }}
{{- if $config.service.pipelines.metrics }}
{{- range $index, $cfg := .Values.Values.presets.spanMetricsMulti.configs }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers (printf "spanmetrics/%d" $index))  }}
{{- end }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "spanmetrics/default")  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.spanMetricsMultiConfig" -}}
connectors:
  routing:
    default_pipelines: [traces/default]
    error_mode: ignore
    table:
      {{- range $index, $cfg := .Values.presets.spanMetricsMulti.configs }}
      - statement: {{ $cfg.selector | toYaml }}
        pipelines: [traces/{{- $index }}]
      {{- end }}
  spanmetrics/default:
{{- if .Values.presets.spanMetrics.namespace }}
    namespace: "{{ .Values.presets.spanMetrics.namespace }}"
{{- else }}
    namespace: ""
{{- end }}
    aggregation_cardinality_limit: {{ .Values.presets.spanMetricsMulti.aggregationCardinalityLimit }}
    histogram:
      explicit:
        buckets: {{ .Values.presets.spanMetricsMulti.defaultHistogramBuckets | toYaml | nindent 12 }}
    {{- if .Values.presets.spanMetricsMulti.collectionInterval }}
    metrics_flush_interval: "{{ .Values.presets.spanMetricsMulti.collectionInterval }}"
    {{- else }}
    metrics_flush_interval: 15s
    {{- end }}
    {{- if .Values.presets.spanMetricsMulti.metricsExpiration }}
    metrics_expiration: "{{ .Values.presets.spanMetricsMulti.metricsExpiration }}"
    {{- else }}
    metrics_expiration: 0
    {{- end }}
    {{- $extraDimensions := include "opentelemetry-collector.spanMetricsMulti.extraDimensions" . }}
    {{- if and $extraDimensions (gt (len $extraDimensions) 0) }}
    dimensions:
    {{- $extraDimensions |  nindent 10 }}
    {{- end }}
  {{- $root := . }}
  {{- range $index, $cfg := .Values.presets.spanMetricsMulti.configs }}
  spanmetrics/{{- $index -}}:
    {{- if $root.Values.presets.spanMetricsMulti.namespace }}
    namespace: "{{ $root.Values.presets.spanMetricsMulti.namespace }}"
    {{- else }}
    namespace: ""
    {{- end }}
    aggregation_cardinality_limit: {{ $root.Values.presets.spanMetricsMulti.aggregationCardinalityLimit }}
    histogram:
      explicit:
        buckets: {{ $cfg.histogramBuckets | toYaml | nindent 12 }}
    {{- if $root.Values.presets.spanMetricsMulti.collectionInterval }}
    metrics_flush_interval: "{{ $root.Values.presets.spanMetricsMulti.collectionInterval }}"
    {{- else }}
    metrics_flush_interval: 15s
    {{- end }}
    {{- if $root.Values.presets.spanMetricsMulti.metricsExpiration }}
    metrics_expiration: "{{ $root.Values.presets.spanMetricsMulti.metricsExpiration }}"
    {{- else }}
    metrics_expiration: 0
    {{- end }}
    {{- if $root.Values.presets.spanMetricsMulti.extraDimensions }}
    dimensions:
    {{- $root.Values.presets.spanMetricsMulti.extraDimensions | toYaml | nindent 10 }}
    {{- end }}
  {{- end }}

{{- end }}

{{- define "opentelemetry-collector.applyKubernetesResourcesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.kubernetesResourcesConfig" .Values | fromYaml) .config }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.kubernetesResourcesConfig" -}}
processors:
  {{- if .Values.presets.kubernetesResources.filterWorkflows.enabled }}
  filter/workflow:
    error_mode: silent
    logs:
      log_record:
        - 'body["object"]["kind"] == "Pod" and not IsMatch(String(body["object"]["metadata"]["ownerReferences"]), ".*StatefulSet.*|.*ReplicaSet.*|.*Job.*|.*DaemonSet.*")'
        - 'body["kind"] == "Pod" and not IsMatch(String(body["metadata"]["ownerReferences"]), ".*StatefulSet.*|.*ReplicaSet.*|.*Job.*|.*DaemonSet.*")'
  {{- end }}
  {{- if .Values.presets.kubernetesResources.filterStatements }}
  filter/workflow-custom:
    error_mode: silent
    logs:
      log_record:
        {{- range $index, $stmt := .Values.presets.kubernetesResources.filterStatements }}
        - {{ $stmt }}
        {{- end }}
  {{- end }}
  transform/entity-event:
    error_mode: silent
    log_statements:
      - context: log
        statements:
          - set(attributes["otel.entity.interval"], Milliseconds(Duration("1h")))
  {{- if .Values.presets.kubernetesResources.dropManagedFields.enabled }}
  transform/remove_managed_fields:
    error_mode: silent
    log_statements:
      - context: log
        statements:
          - delete_key(body["object"]["metadata"], "managedFields")
          - delete_key(body["metadata"], "managedFields")
  {{- end }}
  {{- if .Values.presets.kubernetesResources.transformStatements }}
  transform/kubernetes_transform:
    error_mode: silent
    log_statements:
      {{- range $index, $stmt := .Values.presets.kubernetesResources.transformStatements }}
      - {{ $stmt }}
      {{- end }}
  {{- end }}
  resourcedetection/resource_catalog:
    detectors:
    - eks
    - aks
    - gcp
    - ec2
    - azure
    override: true
    timeout: 2s
    ec2:
      resource_attributes:
        host.name:
          enabled: false
        host.id:
          enabled: false
        host.image.id:
          enabled: false
        host.type:
          enabled: false
    azure:
      resource_attributes:
        host.name:
          enabled: false
        host.id:
          enabled: false
        azure.vm.name:
          enabled: false
        azure.vm.scaleset.name:
          enabled: false
        azure.resourcegroup.name:
          enabled: false
        azure.vm.size:
          enabled: false
    gcp:
      resource_attributes:
        host.id:
          enabled: false
        host.name:
          enabled: false
        host.type:
          enabled: false
        k8s.cluster.name:
          enabled: false
exporters:
  coralogix/resource_catalog:
    timeout: "30s"
    private_key: "${CORALOGIX_PRIVATE_KEY}"
    domain: "{{.Values.global.domain}}"
    application_name: "resource"
    subsystem_name: "catalog"
    logs:
      headers:
        X-Coralogix-Distribution: "helm-otel-integration/{{ .Values.global.version }}"
        x-coralogix-ingress: "metadata-as-otlp-logs/v1"

receivers:
  k8sobjects/resource_catalog:
    objects:
      {{- if .Values.presets.kubernetesResources.periodicCollection.enabled }}
      - name: namespaces
        mode: "pull"
        group: ""
      - name: nodes
        mode: "pull"
        group: ""
      - name: persistentvolumeclaims
        mode: "pull"
        group: ""
      - name: persistentvolumes
        mode: "pull"
        group: ""
      - name: pods
        mode: "pull"
        group: ""
      - name: services
        mode: "pull"
        group: ""
      - name: daemonsets
        mode: "pull"
        group: "apps"
      - name: deployments
        mode: "pull"
        group: "apps"
      - name: replicasets
        mode: "pull"
        group: "apps"
      - name: statefulsets
        mode: "pull"
        group: "apps"
      - name: horizontalpodautoscalers
        mode: "pull"
        group: "autoscaling"
      - name: cronjobs
        mode: "pull"
        group: "batch"
      - name: jobs
        mode: "pull"
        group: "batch"
      - name: ingresses
        mode: "pull"
        group: "extensions"
      - name: ingresses
        mode: "pull"
        group: "networking.k8s.io"
      - name: poddisruptionbudgets
        mode: "pull"
        group: "policy"
      - name: clusterrolebindings
        mode: "pull"
        group: "rbac.authorization.k8s.io"
      - name: clusterroles
        mode: "pull"
        group: "rbac.authorization.k8s.io"
      - name: rolebindings
        mode: "pull"
        group: "rbac.authorization.k8s.io"
      - name: roles
        mode: "pull"
        group: "rbac.authorization.k8s.io"
      {{- end }}
      - name: namespaces
        mode: "watch"
        group: ""
      - name: nodes
        mode: "watch"
        group: ""
      - name: persistentvolumeclaims
        mode: "watch"
        group: ""
      - name: persistentvolumes
        mode: "watch"
        group: ""
      - name: pods
        mode: "watch"
        group: ""
      - name: daemonsets
        mode: "watch"
        group: "apps"
      - name: deployments
        mode: "watch"
        group: "apps"
      - name: replicasets
        mode: "watch"
        group: "apps"
      - name: statefulsets
        mode: "watch"
        group: "apps"
      - name: horizontalpodautoscalers
        mode: "watch"
        group: "autoscaling"
      - name: cronjobs
        mode: "watch"
        group: "batch"
      - name: jobs
        mode: "watch"
        group: "batch"
      - name: ingresses
        mode: "watch"
        group: "extensions"
      - name: ingresses
        mode: "watch"
        group: "networking.k8s.io"
      - name: poddisruptionbudgets
        mode: "watch"
        group: "policy"
      - name: clusterrolebindings
        mode: "watch"
        group: "rbac.authorization.k8s.io"
      - name: clusterroles
        mode: "watch"
        group: "rbac.authorization.k8s.io"
      - name: rolebindings
        mode: "watch"
        group: "rbac.authorization.k8s.io"
      - name: roles
        mode: "watch"
        group: "rbac.authorization.k8s.io"
service:
  pipelines:
    logs/resource_catalog:
      exporters:
        - coralogix/resource_catalog
      processors:
        - memory_limiter
        - resourcedetection/resource_catalog
        - transform/entity-event
        {{- if .Values.presets.kubernetesResources.dropManagedFields.enabled }}
        - transform/remove_managed_fields
        {{- end }}
        {{- if .Values.presets.kubernetesResources.filterWorkflows.enabled }}
        - filter/workflow
        {{- end }}
        {{- if .Values.presets.kubernetesResources.filterStatements }}
        - filter/workflow-custom
        {{- end }}
        - resource/metadata
        {{- if .Values.presets.kubernetesResources.transformStatements }}
        - transform/kubernetes_transform
        {{- end }}
        - batch
      receivers:
        - k8sobjects/resource_catalog
{{- end }}

{{- define "opentelemetry-collector.applyHostEntityEventsConfig" -}}
{{- if not .Values.Values.presets.hostMetrics.enabled }}
{{- fail "hostEntityEvents preset requires hostMetrics preset to be enabled" }}
{{- end }}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.hostEntityEventsConfig" .Values | fromYaml) .config }}
{{- if not (hasKey $config.processors "k8sattributes") }}
{{- $rcPipeline := index $config.service.pipelines "logs/resource_catalog" }}
{{- $_ := set $rcPipeline "processors" (without $rcPipeline.processors "k8sattributes" | uniq) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.hostEntityEventsConfig" -}}
exporters:
  coralogix/resource_catalog:
    timeout: "30s"
    private_key: "${CORALOGIX_PRIVATE_KEY}"
    domain: "{{.Values.global.domain}}"
    application_name: "resource"
    subsystem_name: "catalog"
    logs:
      headers:
        X-Coralogix-Distribution: "helm-otel-integration/{{ .Values.global.version }}"
        x-coralogix-ingress: "metadata-as-otlp-logs/v1"

processors:
  resourcedetection/entity:
    detectors: ["system", "env"]
    timeout: 2s
    override: false
    system:
      resource_attributes:
        host.id:
          enabled: true
        host.cpu.cache.l2.size:
          enabled: true
        host.cpu.stepping:
          enabled: true
        host.cpu.model.name:
          enabled: true
        host.cpu.model.id:
          enabled: true
        host.cpu.family:
          enabled: true
        host.cpu.vendor.id:
          enabled: true
        host.mac:
          enabled: true
        host.ip:
          enabled: true
        os.description:
          enabled: true
  transform/entity-event:
    error_mode: silent
    log_statements:
      - context: log
        statements:
          - set(attributes["otel.entity.id"]["host.id"], resource.attributes["host.id"])
          - merge_maps(attributes, resource.attributes, "insert")
      - context: resource
        statements:
          - keep_keys(attributes, [""])
service:
  pipelines:
    logs/resource_catalog:
      exporters:
        - coralogix/resource_catalog
      processors:
        - memory_limiter
        - resource/metadata
        - k8sattributes
        - resourcedetection/entity
        - resourcedetection/region
        - transform/entity-event
      receivers:
        - hostmetrics
{{- end }}


{{- define "opentelemetry-collector.applyLoadBalancingConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.loadBalancingConfig" .Values | fromYaml) .config }}
{{- $pipelines := list "traces" }}
{{- if .Values.Values.presets.loadBalancing.pipelines }}
  {{- $pipelines = .Values.Values.presets.loadBalancing.pipelines }}
{{- end }}
{{- $includeLogs := has "logs" $pipelines }}
{{- $includeMetrics := has "metrics" $pipelines }}
{{- $includeTraces := has "traces" $pipelines }}
{{- $includeProfiles := has "profiles" $pipelines }}

{{- if and $includeLogs ($config.service.pipelines.logs) (not (has "loadbalancing" $config.service.pipelines.logs.exporters)) }}
{{- $_ := set $config.service.pipelines.logs "exporters" (append $config.service.pipelines.logs.exporters "loadbalancing" | uniq)  }}
{{- end }}
{{- if and $includeMetrics ($config.service.pipelines.metrics) (not (has "loadbalancing" $config.service.pipelines.metrics.exporters)) }}
{{- $_ := set $config.service.pipelines.metrics "exporters" (append $config.service.pipelines.metrics.exporters "loadbalancing" | uniq)  }}
{{- end }}
{{- if and $includeTraces ($config.service.pipelines.traces) (not (has "loadbalancing" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "loadbalancing" | uniq)  }}
{{- end }}
{{- if and $includeProfiles ($config.service.pipelines.profiles) (not (has "loadbalancing" $config.service.pipelines.profiles.exporters)) }}
{{- $_ := set $config.service.pipelines.profiles "exporters" (append $config.service.pipelines.profiles.exporters "loadbalancing" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.loadBalancingConfig" -}}
exporters:
  loadbalancing:
    routing_key: "{{ .Values.presets.loadBalancing.routingKey }}"
    protocol:
      otlp:
        tls:
          insecure: true
    resolver:
      {{- if .Values.presets.loadBalancing.k8s.enabled }}
      k8s:
        {{- if .Values.presets.loadBalancing.k8s.service }}
        service: {{ .Values.presets.loadBalancing.k8s.service | quote }}
        {{- end }}
        {{- if .Values.presets.loadBalancing.k8s.ports }}
        ports:
          {{- range .Values.presets.loadBalancing.k8s.ports }}
          - {{ . }}
          {{- end }}
        {{- end }}
        {{- if .Values.presets.loadBalancing.k8s.timeout }}
        timeout: {{ .Values.presets.loadBalancing.k8s.timeout | quote }}
        {{- end }}
      {{- else }}
      dns:
        hostname: "{{ .Values.presets.loadBalancing.hostname }}"
        {{- if .Values.presets.loadBalancing.dnsResolverInterval }}
        interval: "{{ .Values.presets.loadBalancing.dnsResolverInterval }}"
        {{- end }}
        {{- if .Values.presets.loadBalancing.dnsResolverTimeout }}
        timeout: "{{ .Values.presets.loadBalancing.dnsResolverTimeout }}"
        {{- end }}
      {{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyCoralogixExporterConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.coralogixExporterConfig" .Values | fromYaml) .config }}
{{- $pipeline := list "all" }}
{{- if .Values.Values.presets.coralogixExporter.pipelines }}
  {{- $pipeline = .Values.Values.presets.coralogixExporter.pipelines }}
{{- else if .Values.Values.presets.coralogixExporter.pipeline }}
  {{- $pipeline = list .Values.Values.presets.coralogixExporter.pipeline }}
{{- end }}

{{- $includeLogs := or (has "all" $pipeline) (has "logs" $pipeline) }}
{{- $includeMetrics := or (has "all" $pipeline) (has "metrics" $pipeline) }}
{{- $includeTraces := or (has "all" $pipeline) (has "traces" $pipeline) }}
{{- $includeProfiles := or (has "all" $pipeline) (has "profiles" $pipeline) }}

{{- if and $includeLogs ($config.service.pipelines.logs) (not (has "coralogix" $config.service.pipelines.logs.exporters)) }}
{{- $_ := set $config.service.pipelines.logs "exporters" (append $config.service.pipelines.logs.exporters "coralogix" | uniq) }}
{{- end }}
{{- if and $includeMetrics ($config.service.pipelines.metrics) (not (has "coralogix" $config.service.pipelines.metrics.exporters)) }}
{{- $_ := set $config.service.pipelines.metrics "exporters" (append $config.service.pipelines.metrics.exporters "coralogix" | uniq) }}
{{- end }}
{{- if and $includeTraces ($config.service.pipelines.traces) (not (has "coralogix" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "coralogix" | uniq) }}
{{- end }}
{{- if and $includeProfiles ($config.service.pipelines.profiles) (not (has "coralogix" $config.service.pipelines.profiles.exporters)) }}
{{- $_ := set $config.service.pipelines.profiles "exporters" (append $config.service.pipelines.profiles.exporters "coralogix" | uniq) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.coralogixExporterConfig" -}}
exporters:
  coralogix:
    timeout: "30s"
    private_key: "{{ .Values.presets.coralogixExporter.privateKey }}"
    domain: "{{ .Values.presets.coralogixExporter.domain | default .Values.global.domain }}"
    logs:
      headers:
        X-Coralogix-Distribution: "{{ if eq .Values.distribution "ecs" }}ecs-ec2-integration{{ else }}helm-otel-integration{{ end }}/{{ .Values.presets.coralogixExporter.version | default .Values.global.version }}"
    metrics:
      headers:
        X-Coralogix-Distribution: "helm-otel-integration/{{ .Values.presets.coralogixExporter.version | default .Values.global.version }}"
    traces:
      headers:
        X-Coralogix-Distribution: "helm-otel-integration/{{ .Values.presets.coralogixExporter.version | default .Values.global.version }}"
    profiles:
      headers:
        X-Coralogix-Distribution: "helm-otel-integration/{{ .Values.presets.coralogixExporter.version | default .Values.global.version }}"
    application_name: "{{ .Values.presets.coralogixExporter.defaultApplicationName | default .Values.global.defaultApplicationName }}"
    subsystem_name: "{{ .Values.presets.coralogixExporter.defaultSubsystemName | default .Values.global.defaultSubsystemName }}"
    application_name_attributes:
      {{- if eq .Values.distribution "ecs" }}
      - "aws.ecs.cluster"
      - "aws.ecs.task.definition.family"
      {{- else }}
      - "k8s.namespace.name"
      - "service.namespace"
      {{- end }}
    subsystem_name_attributes:
      {{- if eq .Values.distribution "ecs" }}
      - "aws.ecs.container.name"
      - "aws.ecs.docker.name"
      - "docker.name"
      {{- else }}
      - "k8s.deployment.name"
      - "k8s.statefulset.name"
      - "k8s.daemonset.name"
      - "k8s.cronjob.name"
      {{- if eq .Values.distribution "eks/fargate" }}
      - "k8s.job.name"
      - "k8s.container.name"
      - "k8s.node.name"
      {{- end }}
      - "service.name"
      {{- end }}
    {{- with .Values.presets.coralogixExporter.retryOnFailure }}
    retry_on_failure:
      {{- if hasKey . "enabled" }}
      enabled: {{ .enabled }}
      {{- end }}
      {{- if .initialInterval }}
      initial_interval: "{{ .initialInterval }}"
      {{- end }}
      {{- if .maxInterval }}
      max_interval: "{{ .maxInterval }}"
      {{- end }}
      {{- if hasKey . "maxElapsedTime" }}
      max_elapsed_time: "{{ .maxElapsedTime }}"
      {{- end }}
      {{- if hasKey . "multiplier" }}
      multiplier: {{ .multiplier }}
      {{- end }}
    {{- end }}
    {{- with .Values.presets.coralogixExporter.sendingQueue }}
    sending_queue:
      {{- if hasKey . "enabled" }}
      enabled: {{ .enabled }}
      {{- end }}
      {{- if hasKey . "numConsumers" }}
      num_consumers: {{ .numConsumers }}
      {{- end }}
      {{- if hasKey . "waitForResult" }}
      wait_for_result: {{ .waitForResult }}
      {{- end }}
      {{- if hasKey . "blockOnOverflow" }}
      block_on_overflow: {{ .blockOnOverflow }}
      {{- end }}
      {{- if .sizer }}
      sizer: {{ .sizer | quote }}
      {{- end }}
      {{- if hasKey . "queueSize" }}
      queue_size: {{ .queueSize }}
      {{- end }}
    {{- end }}
{{- end }}

{{- define "opentelemetry-collector.kubernetesAttributesConfig" -}}
processors:
  k8sattributes:
  {{- if or (eq .Values.mode "daemonset") .Values.presets.kubernetesAttributes.nodeFilter.enabled }}
    filter:
      node_from_env_var: K8S_NODE_NAME
  {{- end }}
    passthrough: false
    pod_association:
    - sources:
      - from: resource_attribute
        name: k8s.pod.ip
    - sources:
      - from: resource_attribute
        name: k8s.pod.uid
    - sources:
      - from: connection
    - sources:
      - from: resource_attribute
        name: k8s.job.name
    extract:
      metadata:
        - "k8s.namespace.name"
        - "k8s.replicaset.name"
        - "k8s.statefulset.name"
        - "k8s.daemonset.name"
        - "k8s.cronjob.name"
        - "k8s.job.name"
        - "k8s.node.name"
        - "k8s.pod.name"
        {{- if .Values.presets.kubernetesAttributes.podUid.enabled }}
        - "k8s.pod.uid"
        {{- end }}
        {{- if .Values.presets.kubernetesAttributes.podStartTime.enabled }}
        - "k8s.pod.start_time"
        {{- end }}
      {{- if .Values.presets.kubernetesAttributes.extractAllPodLabels }}
      labels:
        - tag_name: $$1
          key_regex: (.*)
          from: pod
      {{- end }}
      {{- if .Values.presets.kubernetesAttributes.extractAllPodAnnotations }}
      annotations:
        - tag_name: $$1
          key_regex: (.*)
          from: pod
      {{- end }}
  transform/k8s_attributes:
    metric_statements:
    - context: resource
      statements:
      - set(attributes["k8s.deployment.name"], attributes["k8s.replicaset.name"])
      - replace_pattern(attributes["k8s.deployment.name"], "^(.*)-[0-9a-zA-Z]+$", "$$1") where attributes["k8s.replicaset.name"] != nil
      - delete_key(attributes, "k8s.replicaset.name")
    trace_statements:
    - context: resource
      statements:
      - set(attributes["k8s.deployment.name"], attributes["k8s.replicaset.name"])
      - replace_pattern(attributes["k8s.deployment.name"], "^(.*)-[0-9a-zA-Z]+$", "$$1") where attributes["k8s.replicaset.name"] != nil
      - delete_key(attributes, "k8s.replicaset.name")
    log_statements:
    - context: resource
      statements:
      - set(attributes["k8s.deployment.name"], attributes["k8s.replicaset.name"])
      - replace_pattern(attributes["k8s.deployment.name"], "^(.*)-[0-9a-zA-Z]+$", "$$1") where attributes["k8s.replicaset.name"] != nil
      - delete_key(attributes, "k8s.replicaset.name")
{{- end }}

{{- define "opentelemetry-collector.applyEcsAttributesContainerLogsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.ecsAttributesContainerLogsConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.logs) (not (has "ecsattributes/container-logs" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "ecsattributes/container-logs" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.ecsAttributesContainerLogsConfig" -}}
processors:
  ecsattributes/container-logs:
    container_id:
      sources:
        - "log.file.path"
{{- end }}

{{- define "opentelemetry-collector.applyResourceDetectionConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.resourceDetectionConfig" .Values | fromYaml) .config }}
{{- $pipeline := "all" }}
{{- with .Values.Values.presets.resourceDetection.pipeline }}
{{- $pipeline = . }}
{{- end }}
{{- $includeLogs := eq $pipeline "all" }}
{{- $includeMetrics := or (eq $pipeline "all") (eq $pipeline "metrics") }}
{{- $includeTraces := or (eq $pipeline "all") (eq $pipeline "traces") }}
{{- $includeProfiles := or (eq $pipeline "all") (eq $pipeline "profiles") }}
{{- if and $includeLogs ($config.service.pipelines.logs) (not (has "resourcedetection/env" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "resourcedetection/env" | uniq)  }}
{{- end }}
{{- if and $includeLogs ($config.service.pipelines.logs) (not (has "resourcedetection/region" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "resourcedetection/region" | uniq)  }}
{{- end }}
{{- if and $includeMetrics ($config.service.pipelines.metrics) (not (has "resourcedetection/env" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend $config.service.pipelines.metrics.processors "resourcedetection/env" | uniq)  }}
{{- end }}
{{- if and $includeMetrics ($config.service.pipelines.metrics) (not (has "resourcedetection/region" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend $config.service.pipelines.metrics.processors "resourcedetection/region" | uniq)  }}
{{- end }}
{{- if and $includeTraces ($config.service.pipelines.traces) (not (has "resourcedetection/env" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "resourcedetection/env" | uniq)  }}
{{- end }}
{{- if and $includeTraces ($config.service.pipelines.traces) (not (has "resourcedetection/region" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "resourcedetection/region" | uniq)  }}
{{- end }}
{{- if and $includeProfiles ($config.service.pipelines.profiles) (not (has "resourcedetection/env" $config.service.pipelines.profiles.processors)) }}
{{- $_ := set $config.service.pipelines.profiles "processors" (prepend $config.service.pipelines.profiles.processors "resourcedetection/env" | uniq)  }}
{{- end }}
{{- if and $includeProfiles ($config.service.pipelines.profiles) (not (has "resourcedetection/region" $config.service.pipelines.profiles.processors)) }}
{{- $_ := set $config.service.pipelines.profiles "processors" (prepend $config.service.pipelines.profiles.processors "resourcedetection/region" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.resourceDetectionConfig" -}}
processors:
  resourcedetection/env:
    detectors: ["system", "env"]
    timeout: 2s
    override: false
    system:
      resource_attributes:
        host.id:
          enabled: true
  resourcedetection/region:
    detectors: ["gcp", "ec2", "azure", "eks"]
    timeout: 2s
    override: true
    eks:
      node_from_env_var: K8S_NODE_NAME
{{- end }}

{{/* Build the list of port for service */}}
{{- define "opentelemetry-collector.servicePortsConfig" -}}
{{- $ports := deepCopy .Values.ports }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  port: {{ $port.servicePort }}
  targetPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if $port.appProtocol }}
  appProtocol: {{ $port.appProtocol }}
  {{- end }}
{{- if $port.nodePort }}
  nodePort: {{ $port.nodePort }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/* Build the list of port for pod */}}
{{- define "opentelemetry-collector.podPortsConfig" -}}
{{- $ports := deepCopy .Values.ports }}
{{- $distribution := .Values.distribution }}
{{- if .Values.presets.jaegerReceiver.enabled }}
  {{/* Add Jaeger ports only if they don't already exist */}}
  {{- if not (hasKey $ports "jaeger-grpc") }}
  {{- $_ := set $ports "jaeger-grpc" (dict "enabled" true "containerPort" 14250 "servicePort" 14250 "hostPort" 14250 "protocol" "TCP") }}
  {{- end }}
  {{- if not (hasKey $ports "jaeger-thrift") }}
  {{- $_ := set $ports "jaeger-thrift" (dict "enabled" true "containerPort" 14268 "servicePort" 14268 "hostPort" 14268 "protocol" "TCP") }}
  {{- end }}
  {{- if not (hasKey $ports "jaeger-compact") }}
  {{- $_ := set $ports "jaeger-compact" (dict "enabled" true "containerPort" 6831 "servicePort" 6831 "hostPort" 6831 "protocol" "UDP") }}
  {{- end }}
  {{- if not (hasKey $ports "jaeger-binary") }}
  {{- $_ := set $ports "jaeger-binary" (dict "enabled" true "containerPort" 6832 "servicePort" 6832 "hostPort" 6832 "protocol" "TCP") }}
  {{- end }}
{{- end }}
{{- if .Values.presets.zipkinReceiver.enabled }}
  {{/* Add Zipkin port only if it doesn't already exist */}}
  {{- if not (hasKey $ports "zipkin") }}
  {{- $_ := set $ports "zipkin" (dict "enabled" true "containerPort" 9411 "servicePort" 9411 "hostPort" 9411 "protocol" "TCP") }}
  {{- end }}
{{- end }}
{{- if .Values.presets.statsdReceiver.enabled }}
  {{/* Add StatsD port only if it doesn't already exist */}}
  {{- if not (hasKey $ports "statsd") }}
  {{- $_ := set $ports "statsd" (dict "enabled" true "containerPort" 8125 "servicePort" 8125 "hostPort" 8125 "protocol" "UDP") }}
  {{- end }}
{{- end }}
{{- if .Values.presets.otlpReceiver.enabled }}
  {{/* Add OTLP ports only if they don't already exist */}}
  {{- if not (hasKey $ports "otlp") }}
  {{- $_ := set $ports "otlp" (dict "enabled" true "containerPort" 4317 "servicePort" 4317 "hostPort" 4317 "protocol" "TCP" "appProtocol" "grpc") }}
  {{- end }}
  {{- if not (hasKey $ports "otlp-http") }}
  {{- $_ := set $ports "otlp-http" (dict "enabled" true "containerPort" 4318 "servicePort" 4318 "hostPort" 4318 "protocol" "TCP") }}
  {{- end }}
{{- end }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if and $.isAgent $port.hostPort (ne $distribution "gke/autopilot") }}
  hostPort: {{ $port.hostPort }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyKubernetesEventsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.kubernetesEventsConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append $config.service.pipelines.logs.receivers "k8sobjects" | uniq)  }}
{{- if and ($config.service.pipelines.logs) (not (has "resource/kube-events" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "resource/kube-events" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.logs) (not (has "transform/kube-events" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (append $config.service.pipelines.logs.processors "transform/kube-events" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.kubernetesEventsConfig" -}}
receivers:
  k8sobjects:
    objects:
      - name: events
        mode: "watch"
        group: "events.k8s.io"
        exclude_watch_type:
          - "DELETED"
processors:
  resource/kube-events:
    attributes:
      - key: service.name
        value: "kube-events"
        action: upsert
      {{- if or .Values.presets.kubernetesEvents.clusterName .Values.global.clusterName }}
      - key: k8s.cluster.name
        value: "{{ .Values.presets.kubernetesEvents.clusterName | default .Values.global.clusterName }}"
        action: upsert
      {{- end }}
  transform/kube-events:
    log_statements:
      - context: log
        statements:
          - keep_keys(body["object"], ["type", "eventTime", "reason", "regarding", "note", "metadata", "deprecatedFirstTimestamp", "deprecatedLastTimestamp"])
          - keep_keys(body["object"]["metadata"], ["creationTimestamp"])
          - keep_keys(body["object"]["regarding"], ["kind", "name", "namespace"])
{{- end }}

{{- define "opentelemetry-collector.applyHeadSamplingConfig" -}}
{{- $exporterName := "coralogix" }}
{{- if and (.Values.Values.presets.loadBalancing) (.Values.Values.presets.loadBalancing.enabled) }}
{{- $exporterName = "loadbalancing" }}
{{- end }}

{{- $config := mustMergeOverwrite (include "opentelemetry-collector.headSamplingConfig" (dict "Values" .Values "exporterName" $exporterName) | fromYaml) .config }}

{{- if and ($config.service.pipelines.traces) (has "coralogix" $config.service.pipelines.traces.exporters) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (without $config.service.pipelines.traces.exporters "coralogix")  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (has "loadbalancing" $config.service.pipelines.traces.exporters) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (without $config.service.pipelines.traces.exporters "loadbalancing")  }}
{{- end }}

{{- if and ($config.service.pipelines.traces) (not (has "forward/sampled" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "forward/sampled" | uniq)  }}
{{- end }}

{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.headSamplingConfig" -}}
{{- $exporterName := .exporterName | default "coralogix" }}
processors:
  probabilistic_sampler:
    sampling_percentage: {{ .Values.Values.presets.headSampling.percentage }}
    mode: {{ .Values.Values.presets.headSampling.mode }}
connectors:
  forward/sampled: {}
service:
  pipelines:
    traces/sampled:
      receivers:
         - forward/sampled
      processors:
        - batch
        - probabilistic_sampler
      exporters:
        - {{ $exporterName }}
{{- end }}

{{- define "opentelemetry-collector.applyCollectorMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.collectorMetricsConfig" .Values | fromYaml) .config }}
{{- $pipeline := "metrics" }}
{{- with .Values.Values.presets.collectorMetrics.pipeline }}
{{- $pipeline = . }}
{{- end }}
{{- $includeMetrics := eq $pipeline "metrics" }}
{{- $monitorsEnabled := or .Values.Values.podMonitor.enabled .Values.Values.serviceMonitor.enabled }}
{{- if and $includeMetrics (not $monitorsEnabled) ($config.service.pipelines.metrics) (not (has "prometheus" $config.service.pipelines.metrics.receivers)) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "prometheus" | uniq)  }}
{{- end }}
{{- if and $includeMetrics ($config.service.pipelines.metrics) (not (has "transform/prometheus" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "transform/prometheus" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.collectorMetricsConfig" -}}
{{- $monitorsEnabled := or .Values.podMonitor.enabled .Values.serviceMonitor.enabled }}
{{- if not $monitorsEnabled }}
receivers:
  prometheus:
    config:
      scrape_configs:
        - job_name: opentelemetry-collector
          {{- if .Values.presets.collectorMetrics.scrapeInterval }}
          scrape_interval: "{{ .Values.presets.collectorMetrics.scrapeInterval }}"
          {{- else }}
          scrape_interval: 30s
          {{- end }}
          static_configs:
            - targets:
                - {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "8888" "context" $) | quote }}
{{- end }}

processors:
  transform/prometheus:
    error_mode: ignore
    metric_statements:
      - context: metric
        statements:
          - replace_pattern(metric.name, "_total$", "") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_process_cpu_seconds_seconds$", "otelcol_process_cpu_seconds") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_process_memory_rss_bytes$", "otelcol_process_memory_rss_bytes") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_process_runtime_heap_alloc_bytes_bytes$", "otelcol_process_runtime_heap_alloc_bytes") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_process_runtime_total_alloc_bytes_bytes$", "otelcol_process_runtime_total_alloc_bytes") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_process_runtime_total_sys_memory_bytes_bytes$", "otelcol_process_runtime_total_sys_memory_bytes") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_fileconsumer_open_files$", "otelcol_fileconsumer_open_files_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_fileconsumer_reading_files$", "otelcol_fileconsumer_reading_files_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_otelsvc_k8s_ip_lookup_miss$", "otelcol_otelsvc_k8s_ip_lookup_miss_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_otelsvc_k8s_pod_added$", "otelcol_otelsvc_k8s_pod_added_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_otelsvc_k8s_pod_table_size_ratio$", "otelcol_otelsvc_k8s_pod_table_size_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_otelsvc_k8s_pod_updated$", "otelcol_otelsvc_k8s_pod_updated_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_otelsvc_k8s_pod_deleted$", "otelcol_otelsvc_k8s_pod_deleted_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
          - replace_pattern(metric.name, "^otelcol_processor_filter_spans\\.filtered$", "otelcol_processor_filter_spans.filtered_ratio") where resource.attributes["service.name"] == "opentelemetry-collector"
      - context: resource
        statements:
          - set(attributes["k8s.pod.ip"], attributes["net.host.name"]) where attributes["service.name"] == "opentelemetry-collector"
          - delete_key(attributes, "service_name") where attributes["service.name"] == "opentelemetry-collector"
      - context: datapoint
        statements:
          - delete_key(attributes, "service_name") where resource.attributes["service.name"] == "opentelemetry-collector"
          - delete_key(attributes, "otel_scope_name") where attributes["service.name"] == "opentelemetry-collector"

service:
  telemetry:
    metrics:
      readers:
        - pull:
            exporter:
              prometheus:
                host: {{ include "opentelemetry-collector.envHost" (dict "env" "MY_POD_IP" "context" $) | quote }}
                port: 8888
{{- end }}

{{- define "opentelemetry-collector.applyJaegerReceiverConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.jaegerReceiverConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.traces) (not (has "jaeger" $config.service.pipelines.traces.receivers)) }}
{{- $_ := set $config.service.pipelines.traces "receivers" (append $config.service.pipelines.traces.receivers "jaeger" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.jaegerReceiverConfig" -}}
receivers:
  jaeger:
    protocols:
      grpc:
        endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "14250" "context" $) | quote }}
      thrift_http:
        endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "14268" "context" $) | quote }}
      thrift_compact:
        endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "6831" "context" $) | quote }}
      thrift_binary:
        endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "6832" "context" $) | quote }}
{{- end }}

{{- define "opentelemetry-collector.applyZipkinReceiverConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.zipkinReceiverConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.traces) (not (has "zipkin" $config.service.pipelines.traces.receivers)) }}
{{- $_ := set $config.service.pipelines.traces "receivers" (append $config.service.pipelines.traces.receivers "zipkin" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.zipkinReceiverConfig" -}}
receivers:
  zipkin:
    endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "9411" "context" $) | quote }}
{{- end }}

{{- define "opentelemetry-collector.applyStatsdReceiverConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.statsdReceiverConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.metrics) (not (has "statsd" $config.service.pipelines.metrics.receivers)) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "statsd" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.statsdReceiverConfig" -}}
receivers:
  statsd:
    endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "8125" "context" $) | quote }}
{{- end }}

{{- define "opentelemetry-collector.applyAwsecsContainerMetricsdReceiverConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.awsecsContainerMetricsdReceiverConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.metrics) (not (has "awsecscontainermetricsd" $config.service.pipelines.metrics.receivers)) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "awsecscontainermetricsd" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.awsecsContainerMetricsdReceiverConfig" -}}
receivers:
  awsecscontainermetricsd: {}
{{- end }}

{{- define "opentelemetry-collector.applyBatchProcessorConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.batchProcessorConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.logs) (not (has "batch" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (append $config.service.pipelines.logs.processors "batch" | uniq) }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "batch" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "batch" | uniq) }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (not (has "batch" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "batch" | uniq) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.batchProcessorConfig" -}}
processors:
  batch:
    send_batch_size: {{ .Values.presets.batch.sendBatchSize }}
    send_batch_max_size: {{ .Values.presets.batch.sendBatchMaxSize }}
    timeout: {{ .Values.presets.batch.timeout }}
{{- end }}

{{- define "opentelemetry-collector.applyOtlpReceiverConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.otlpReceiverConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.traces) (not (has "otlp" $config.service.pipelines.traces.receivers)) }}
{{- $_ := set $config.service.pipelines.traces "receivers" (append $config.service.pipelines.traces.receivers "otlp" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "otlp" $config.service.pipelines.metrics.receivers)) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "otlp" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.logs) (not (has "otlp" $config.service.pipelines.logs.receivers)) }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append $config.service.pipelines.logs.receivers "otlp" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.profiles) (not (has "otlp" $config.service.pipelines.profiles.receivers)) }}
{{- $_ := set $config.service.pipelines.profiles "receivers" (append $config.service.pipelines.profiles.receivers "otlp" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.otlpReceiverConfig" -}}
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "4317" "context" $) | quote }}
        # Default otlp grpc server message size limit is 4mib, which might be too low.
        max_recv_msg_size_mib: {{ .Values.presets.otlpReceiver.maxRecvMsgSizeMiB }}
      http:
        endpoint: {{ include "opentelemetry-collector.envEndpoint" (dict "env" "MY_POD_IP" "port" "4318" "context" $) | quote }}
{{- end }}

{{- define "opentelemetry-collector.applyZpagesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.zpagesConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.extensions) (not (has "zpages" $config.service.extensions)) }}
{{- $_ := set $config.service "extensions" (append $config.service.extensions "zpages" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.zpagesConfig" -}}
extensions:
  zpages:
    endpoint: {{ .Values.presets.zpages.endpoint }}
{{- end }}

{{- define "opentelemetry-collector.applyPprofConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.pprofConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.extensions) (not (has "pprof" $config.service.extensions)) }}
{{- $_ := set $config.service "extensions" (append $config.service.extensions "pprof" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.pprofConfig" -}}
extensions:
  pprof:
    endpoint: {{ .Values.presets.pprof.endpoint }}
{{- end }}

{{- define "opentelemetry-collector.applyTransactionsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.transactionsConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.traces) (not (has "groupbytrace/transactions" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "groupbytrace/transactions" | uniq) }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (not (has "coralogix" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (append $config.service.pipelines.traces.processors "coralogix" | uniq) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.transactionsConfig" -}}
processors:
  groupbytrace/transactions:
    wait_duration: {{ .Values.presets.transactions.waitDuration }}
  coralogix:
    transactions:
      enabled: true
{{- end }}

{{- define "opentelemetry-collector.chartMetadataAttributes" -}}
helm.chart.{{ .Chart.Name }}.version: "{{ .Chart.Version }}"
{{- end }}

{{/*
Apply EKS Fargate configuration
*/}}
{{- define "opentelemetry-collector.applyEksFargateConfig" -}}
{{- $config := .config }}
{{- $eksFargateConfig := include "opentelemetry-collector.eksFargateConfig" .Values | fromYaml }}
{{- $config = mergeOverwrite $config $eksFargateConfig }}

{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.eksFargateConfig" -}}
extensions:
  k8s_observer:
    auth_type: serviceAccount
    observe_pods: true
    observe_nodes: true

receivers:
  receiver_creator:
    watch_observers: [k8s_observer]
    receivers:
      kubeletstats:
        config:
          auth_type: serviceAccount
          collection_interval: "{{ .Values.presets.eksFargate.kubeletStats.collectionInterval }}"
          endpoint: "`endpoint`:`kubelet_endpoint_port`"
          insecure_skip_verify: true
          extra_metadata_labels:
          - container.id
          metric_groups:
          - container
          - pod
          - node
        {{- if .Values.presets.eksFargate.monitoringCollector }}
        rule: type == "k8s.node" && labels["OTEL-collector-node"] == "true"
        {{- else }}
        rule: type == "k8s.node" && name contains "fargate" && name != "${env:K8S_NODE_NAME}"
        {{- end }}

service:
  pipelines:
    {{- if not .Values.presets.eksFargate.monitoringCollector }}
    metrics/kubeletstats:
      receivers: [receiver_creator]
      processors:
        - memory_limiter
        - resource/metadata
        {{- if .Values.presets.resourceDetection.enabled }}
        - resourcedetection/region
        - resourcedetection/env
        {{- end }}
        {{- if .Values.presets.kubernetesAttributes.enabled }}
        - k8sattributes
        - transform/k8s_attributes
        {{- end }}
      exporters: [coralogix]
    {{- end }}
    metrics/colmon:
      receivers: [receiver_creator]
      processors:
        - memory_limiter
        - resource/metadata
        {{- if .Values.presets.resourceDetection.enabled }}
        - resourcedetection/region
        - resourcedetection/env
        {{- end }}
        {{- if .Values.presets.kubernetesAttributes.enabled }}
        - k8sattributes
        - transform/k8s_attributes
        {{- end }}
      exporters: [coralogix]
  extensions: [health_check, k8s_observer]
{{- end }}


{{- define "opentelemetry-collector.applyEcsLogsCollectionConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.ecsLogsCollectionConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append $config.service.pipelines.logs.receivers "filelog" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.ecsLogsCollectionConfig" -}}
receivers:
  filelog:
    include: [ /hostfs/var/lib/docker/containers/*/*.log ]
    include_file_name: false
    include_file_path: true
    start_at: end
    force_flush_period: {{ $.Values.presets.ecsLogsCollection.forceFlushPeriod }}
    {{- with $.Values.presets.ecsLogsCollection.multiline }}
    multiline:
      {{- if .lineStartPattern }}
      line_start_pattern: {{ .lineStartPattern | quote }}
      {{- end }}
      {{- if .lineEndPattern }}
      line_end_pattern: {{ .lineEndPattern | quote }}
      {{- end }}
      {{- if hasKey . "omitPattern" }}
      omit_pattern: {{ .omitPattern }}
      {{- end }}
    {{- end }}
    operators:
      - type: router
        id: docker_log_json_parser
        routes:
          - output: json_parser
            expr: 'body matches "^\\{\"log\".*\\}"'
        default: move_log_file_path
      - type: json_parser
        parse_from: body
        parse_to: body
        output: recombine
        timestamp:
          parse_from: body.time
          layout: '%Y-%m-%dT%H:%M:%S.%fZ'
      - type: recombine
        id: recombine
        output: move_log_file_path
        combine_field: body.log
        source_identifier: attributes["log.file.path"]
        is_last_entry: body.log endsWith "\n"
        force_flush_period: 10s
        on_error: send
        combine_with: ""
      - type: move
        id: move_log_file_path
        from: attributes["log.file.path"]
        to: resource["log.file.path"]
{{- end }}
