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
{{- if .Values.presets.logsCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyLogsCollectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
{{- end }}
{{- if .Values.presets.profilesCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyProfilesConfig" (dict "Values" $data "config" $config) | fromYaml) }}
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
{{- if .Values.presets.loadBalancing.enabled }}
{{- $config = (include "opentelemetry-collector.applyLoadBalancingConfig" (dict "Values" $data "config" $config) | fromYaml) }}
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
{{- if .Values.presets.fleetManagement.enabled }}
{{- $config = (include "opentelemetry-collector.applyFleetManagementConfig" (dict "Values" $data "config" $config) | fromYaml) }}
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
{{- $config = (include "opentelemetry-collector.applyBatchProcessorAsLast" (dict "Values" $data "config" $config) | fromYaml) }}
{{- tpl (toYaml $config) . }}
{{- end }}

{{/*
Build config file for deployment OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.deploymentConfig" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- if .Values.presets.logsCollection.enabled }}
{{- $config = (include "opentelemetry-collector.applyLogsCollectionConfig" (dict "Values" $data "config" $config) | fromYaml) }}
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
{{- if .Values.presets.fleetManagement.enabled }}
{{- $config = (include "opentelemetry-collector.applyFleetManagementConfig" (dict "Values" $data "config" $config) | fromYaml) }}
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
              - ${env:MY_POD_IP}:8888
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
    root_path: /hostfs
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
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.clusterMetricsConfig" -}}
receivers:
  k8s_cluster:
    {{- if .Values.presets.clusterMetrics.collectionInterval }}
    collection_interval: "{{ .Values.presets.clusterMetrics.collectionInterval }}"
    {{- else }}
    collection_interval: 10s
    {{- end }}
{{- end }}

{{- define "opentelemetry-collector.applyKubeletMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.kubeletMetricsConfig" .Values | fromYaml) .config }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "kubeletstats" | uniq)  }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "metricstransform/kubeletstatscpu" | uniq)  }}
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
    endpoint: "${env:K8S_NODE_IP}:10250"
    collect_all_network_interfaces:
      pod: false
      node: true
processors:
  metricstransform/kubeletstatscpu:
    transforms:
      - include: container.cpu.usage
        action: update
        new_name: container.cpu.utilization
      - include: k8s.pod.cpu.usage
        action: update
        new_name: k8s.pod.cpu.utilization
      - include: k8s.node.cpu.usage
        action: update
        new_name: k8s.node.cpu.utilization
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
# (body startsWith "{\"level\":\"debug") or
      {{- end }}
      {{- if .Values.presets.logsCollection.extraFilelogOperators }}
      {{- .Values.presets.logsCollection.extraFilelogOperators | toYaml | nindent 6 }}
      {{- end }}
{{- end }}


{{- define "opentelemetry-collector.profilesCollectionConfig" -}}
exporters:
  coralogix/profiles:
    timeout: "30s"
    private_key: "${CORALOGIX_PRIVATE_KEY}"
    domain: "{{.Values.global.domain}}"
    application_name: "resource"
    subsystem_name: "catalog"
    batcher:
      enabled: true
      min_size: 1024
      max_size: 2048
      sizer: "items"
      flush_timeout: "1s"
service:
  pipelines:
    profiles:
      receivers:
        - otlp
      processors:
        - memory_limiter
        - resource/metadata
      exporters:
        - coralogix/profiles
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
          - targets: [ "${env:K8S_NODE_IP}:10250" ]
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
{{- if and ($config.service.pipelines.metrics) (not (has "transform/reduce" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "transform/reduce" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.reduceResourceAttributesConfig" -}}
processors:
  transform/reduce:
    error_mode: ignore
    metric_statements:
      - context: resource
        statements:
           # Removing UIDS from k8scluster / k8sattributes
          - delete_key(attributes, "container.id")
          - delete_key(attributes, "k8s.pod.uid")
          - delete_key(attributes, "k8s.replicaset.uid")
          - delete_key(attributes, "k8s.daemonset.uid")
          - delete_key(attributes, "k8s.deployment.uid")
          - delete_key(attributes, "k8s.statefulset.uid")
          - delete_key(attributes, "k8s.cronjob.uid")
          - delete_key(attributes, "k8s.job.uid")
          - delete_key(attributes, "k8s.hpa.uid")
          - delete_key(attributes, "k8s.namespace.uid")
          - delete_key(attributes, "k8s.node.uid")
          # Removing Prometheus receiver net.host.name + port as it's available in service.instance.id
          - delete_key(attributes, "net.host.name")
          - delete_key(attributes, "net.host.port")

{{- end }}

{{- define "opentelemetry-collector.applyFleetManagementConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.fleetManagementConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.extensions) (not (has "opamp" $config.service.extensions)) }}
{{- $_ := set $config.service "extensions" (append $config.service.extensions "opamp" | uniq)  }}
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
        non_identifying_attributes:
        {{- if .Values.presets.fleetManagement.agentType }}
          cx.agent.type: "{{.Values.presets.fleetManagement.agentType}}"
        {{- end }}
        {{- if .Values.presets.fleetManagement.clusterName }}
          cx.cluster.name: "{{.Values.presets.fleetManagement.clusterName}}"
        {{- end }}
        {{- if .Values.presets.fleetManagement.integrationID }}
          cx.integrationID: "{{.Values.presets.fleetManagement.integrationID}}"
        {{- end }}
          k8s.node.name: ${env:KUBE_NODE_NAME}
{{- end }}

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
{{- if or (.Values.presets.spanMetrics.spanNameReplacePattern) (.Values.presets.spanMetrics.dbMetrics.enabled) (.Values.presets.spanMetrics.transformStatements) }}
processors:
{{- end}}
{{- if .Values.presets.spanMetrics.spanNameReplacePattern }}
  transform/span_name:
    trace_statements:
      - context: span
        statements:
        {{- range $index, $pattern := .Values.presets.spanMetrics.spanNameReplacePattern }}
        - replace_pattern(name, "{{ $pattern.regex }}", "{{ $pattern.replacement }}")
        {{- end}}
{{- end }}
{{- if .Values.presets.spanMetrics.dbMetrics.enabled }}
  filter/db_spanmetrics:
    traces:
      span:
        - 'attributes["db.system"] == nil'
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
{{- if .Values.presets.spanMetrics.dbMetrics.enabled }}
service:
  pipelines:
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
    match_once: false
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
  transform/entity-event:
    error_mode: silent
    log_statements:
      - context: log
        statements:
          - set(attributes["otel.entity.interval"], Milliseconds(Duration("1h")))
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
        {{- if .Values.presets.kubernetesResources.filterWorkflows.enabled }}
        - filter/workflow
        {{- end }}
        - resource/metadata
        - batch
      receivers:
        - k8sobjects/resource_catalog
{{- end }}

{{- define "opentelemetry-collector.applyHostEntityEventsConfig" -}}
{{- if not .Values.Values.presets.hostMetrics.enabled }}
{{- fail "hostEntityEvents preset requires hostMetrics preset to be enabled" }}
{{- end }}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.hostEntityEventsConfig" .Values | fromYaml) .config }}
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
{{- if and ($config.service.pipelines.traces) (not (has "loadbalancing" $config.service.pipelines.traces.exporters)) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "loadbalancing" | uniq)  }}
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
      dns:
        hostname: "{{ .Values.presets.loadBalancing.hostname }}"
        {{- if .Values.presets.loadBalancing.dnsResolverInterval }}
        interval: "{{ .Values.presets.loadBalancing.dnsResolverInterval }}"
        {{- end }}
        {{- if .Values.presets.loadBalancing.dnsResolverTimeout }}
        timeout: "{{ .Values.presets.loadBalancing.dnsResolverTimeout }}"
        {{- end }}
{{- end }}

{{- define "opentelemetry-collector.kubernetesAttributesConfig" -}}
processors:
  k8sattributes:
  {{- if eq .Values.mode "daemonset" }}
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
        - "k8s.pod.uid"
        - "k8s.pod.start_time"
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

{{- define "opentelemetry-collector.applyResourceDetectionConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.resourceDetectionConfig" .Values | fromYaml) .config }}
{{- if and ($config.service.pipelines.logs) (not (has "resourcedetection/env" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "resourcedetection/env" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.logs) (not (has "resourcedetection/region" $config.service.pipelines.logs.processors)) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend $config.service.pipelines.logs.processors "resourcedetection/region" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "resourcedetection/env" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend $config.service.pipelines.metrics.processors "resourcedetection/env" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "resourcedetection/region" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend $config.service.pipelines.metrics.processors "resourcedetection/region" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (not (has "resourcedetection/env" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "resourcedetection/env" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.traces) (not (has "resourcedetection/region" $config.service.pipelines.traces.processors)) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend $config.service.pipelines.traces.processors "resourcedetection/region" | uniq)  }}
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
    detectors: ["gcp", "ec2", "azure"]
    timeout: 2s
    override: true
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
{{- if and ($config.service.pipelines.metrics) (not (has "prometheus" $config.service.pipelines.metrics.receivers)) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "prometheus" | uniq)  }}
{{- end }}
{{- if and ($config.service.pipelines.metrics) (not (has "transform/prometheus" $config.service.pipelines.metrics.processors)) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (append $config.service.pipelines.metrics.processors "transform/prometheus" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.collectorMetricsConfig" -}}
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
                - ${env:MY_POD_IP}:8888

processors:
  transform/prometheus:
    error_mode: ignore
    metric_statements:
      - context: metric
        statements:
          - replace_pattern(name, "_total$", "")
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
                host: ${env:MY_POD_IP}
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
        endpoint: ${env:MY_POD_IP}:14250
      thrift_http:
        endpoint: ${env:MY_POD_IP}:14268
      thrift_compact:
        endpoint: ${env:MY_POD_IP}:6831
      thrift_binary:
        endpoint: ${env:MY_POD_IP}:6832
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
    endpoint: ${env:MY_POD_IP}:9411
{{- end }}
