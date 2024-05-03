{{/*
Constructs the final config for the given collector

This allows a user to supply a scrape_configs_file. This file is templated and loaded as a yaml array.
If a user has already supplied a prometheus receiver config, the file's config is appended. Finally,
the config is written as YAML.
*/}}
{{- define "opentelemetry-kube-stack.config" -}}
{{- $collector := .collector }}
{{- $config := .collector.config }}
{{- if .collector.scrape_configs_file }}
{{- $config = (include "opentelemetry-kube-stack.collector.appendPrometheusScrapeFile" . | fromYaml) }}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.kubernetesAttributes.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyKubernetesAttributesConfig" (dict "collector" $collector) | fromYaml) }}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.logsCollection.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyLogsCollectionConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.hostMetrics.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyHostMetricsConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.kubernetesAttributes.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyKubernetesAttributesConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.kubeletMetrics.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyKubeletMetricsConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.kubernetesEvents.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyKubernetesEventsConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.clusterMetrics.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyClusterMetricsConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.batchProcessor.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyBatchProcessorConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.otlpExporter.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyOTLPExporter" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- toYaml $collector.config | nindent 4 }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.appendPrometheusScrapeFile" -}}
{{- $loaded_file := (.Files.Get .collector.scrape_configs_file) }}
{{- $loaded_config := (fromYamlArray (tpl $loaded_file .)) }}
{{- $prom_override := (dict "receivers" (dict "prometheus" (dict "config" (dict "scrape_configs" $loaded_config)))) }}
{{- if (dig "receivers" "prometheus" "config" "scrape_configs" false .collector.config) }}
{{- $merged_prom_scrape_configs := (concat .collector.config.receivers.prometheus.config.scrape_configs $loaded_config) }}
{{- $prom_override = (dict "receivers" (dict "prometheus" (dict "config" (dict "scrape_configs" $merged_prom_scrape_configs)))) }}
{{- end }}
{{- (mergeOverwrite .collector.config $prom_override) | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyKubernetesAttributesConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.kubernetesAttributesConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "logs" false $config) (not (has "k8sattributes" (dig "service" "pipelines" "logs" "processors" list $config))) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend ($config.service.pipelines.logs.processors | default list) "k8sattributes" | uniq)  }}
{{- end }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "k8sattributes" (dig "service" "pipelines" "metrics" "processors" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend ($config.service.pipelines.metrics.processors | default list) "k8sattributes" | uniq)  }}
{{- end }}
{{- if and (dig "service" "pipelines" "traces" false $config) (not (has "k8sattributes" (dig "service" "pipelines" "traces" "processors" list $config))) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend ($config.service.pipelines.traces.processors | default list) "k8sattributes" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.kubernetesAttributesConfig" -}}
processors:
  k8sattributes:
  {{- if eq .mode "daemonset" }}
    filter:
      node_from_env_var: K8S_NODE_NAME
  {{- end }}
    passthrough: false
    pod_association:
    - sources:
      - from: resource_attribute
        name: k8s.pod.uid
    - sources:
      - from: resource_attribute
        name: k8s.pod.name
      - from: resource_attribute
        name: k8s.namespace.name
      - from: resource_attribute
        name: k8s.node.name
    - sources:
      - from: resource_attribute
        name: k8s.pod.ip
    - sources:
      - from: resource_attribute
        name: k8s.pod.name
      - from: resource_attribute
        name: k8s.namespace.name
    - sources:
      - from: connection
    extract:
      metadata:
        - k8s.namespace.name
        - k8s.pod.name
        - k8s.pod.uid
        - k8s.node.name
        - k8s.pod.start_time
        - k8s.deployment.name
        - k8s.replicaset.name
        - k8s.replicaset.uid
        - k8s.daemonset.name
        - k8s.daemonset.uid
        - k8s.job.name
        - k8s.job.uid
        - k8s.container.name
        - k8s.cronjob.name
        - k8s.statefulset.name
        - k8s.statefulset.uid
        - container.image.tag
        - container.image.name
        - k8s.cluster.uid
      labels:
      - tag_name: service.name
        key: app.kubernetes.io/name
        from: pod
      - tag_name: service.name
        key: k8s-app
        from: pod
      - tag_name: k8s.app.instance
        key: app.kubernetes.io/instance
        from: pod
      - tag_name: service.version
        key: app.kubernetes.io/version
        from: pod
      - tag_name: k8s.app.component
        key: app.kubernetes.io/component
        from: pod
      {{- if .presets.kubernetesAttributes.extractAllPodLabels }}
      - tag_name: $$1
        key_regex: (.*)
        from: pod
      {{- end }}
      {{- if .presets.kubernetesAttributes.extractAllPodAnnotations }}
      annotations:
      - tag_name: $$1
        key_regex: (.*)
        from: pod
      {{- end }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyHostMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.hostMetricsConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "hostmetrics" (dig "service" "pipelines" "metrics" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append ($config.service.pipelines.metrics.receivers | default list) "hostmetrics" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.hostMetricsConfig" -}}
receivers:
  hostmetrics:
    root_path: /hostfs
    collection_interval: 10s
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
          metrics:
            system.filesystem.utilization:
              enabled: true
          exclude_mount_points:
            mount_points:
              - /dev/*
              - /proc/*
              - /sys/*
              - /run/k3s/containerd/*
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
        network:
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyClusterMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.clusterMetricsConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "k8s_cluster" (dig "service" "pipelines" "metrics" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append ($config.service.pipelines.metrics.receivers | default list) "k8s_cluster" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.clusterMetricsConfig" -}}
receivers:
  k8s_cluster:
    collection_interval: 10s
    auth_type: serviceAccount
    node_conditions_to_report: [Ready, MemoryPressure, DiskPressure, NetworkUnavailable]
    allocatable_types_to_report: [cpu, memory, storage]
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyKubeletMetricsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.kubeletMetricsConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "kubeletstats" (dig "service" "pipelines" "metrics" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append ($config.service.pipelines.metrics.receivers | default list) "kubeletstats" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.kubeletMetricsConfig" -}}
receivers:
  kubeletstats:
    collection_interval: "15s"
    auth_type: "serviceAccount"
    insecure_skip_verify: true
    # For this scrape to work, the RBAC must have `nodes/stats` GET access.
    endpoint: "https://${env:OTEL_K8S_NODE_IP}:10250"
    extra_metadata_labels:
    - container.id
    - k8s.volume.type
    metric_groups:
    - node
    - pod
    - volume
    - container
    k8s_api_config:
        auth_type: serviceAccount
    metrics:
        # k8s.pod.cpu.utilization is being deprecated
        k8s.pod.cpu.usage:
            enabled: true
        k8s.node.uptime:
            enabled: true
        k8s.pod.uptime:
            enabled: true
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyLogsCollectionConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.logsCollectionConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "logs" false $config) (not (has "filelog" (dig "service" "pipelines" "logs" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append ($config.service.pipelines.logs.receivers | default list) "filelog" | uniq)  }}
{{- end }}
{{- if .collector.presets.logsCollection.storeCheckpoints}}
{{- $_ := set $config.service "extensions" (append ($config.service.extensions | default list) "file_storage" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.logsCollectionConfig" -}}
{{- if .presets.logsCollection.storeCheckpoints }}
extensions:
  file_storage:
    directory: /var/lib/otelcol
{{- end }}
receivers:
  filelog:
    include:
      - /var/log/pods/*/*/*.log
    start_at: beginning
    include_file_path: true
    include_file_name: false
    operators:
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
        regex: "^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$"
        timestamp:
          parse_from: attributes.time
          layout_type: gotime
          layout: "2006-01-02T15:04:05.999999999Z07:00"
      - type: recombine
        id: crio-recombine
        output: extract_metadata_from_filepath
        combine_field: attributes.log
        source_identifier: attributes["log.file.path"]
        is_last_entry: "attributes.logtag == 'F'"
        combine_with: ""
      # Parse CRI-Containerd format
      - type: regex_parser
        id: parser-containerd
        regex: "^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$"
        timestamp:
          parse_from: attributes.time
          layout: "%Y-%m-%dT%H:%M:%S.%LZ"
      - type: recombine
        id: containerd-recombine
        output: extract_metadata_from_filepath
        combine_field: attributes.log
        source_identifier: attributes["log.file.path"]
        is_last_entry: "attributes.logtag == 'F'"
        combine_with: ""
      # Parse Docker format
      - type: json_parser
        id: parser-docker
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: attributes.time
          layout: "%Y-%m-%dT%H:%M:%S.%LZ"
      # Extract metadata from file path
      - type: regex_parser
        id: extract_metadata_from_filepath
        regex: '^.*\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[a-f0-9\-]+)\/(?P<container_name>[^\._]+)\/(?P<restart_count>\d+)\.log$'
        parse_from: attributes["log.file.path"]
      # Clean up log body
      - type: move
        from: attributes.log
        to: body
        if: "attributes.body != nil"
      # Rename attributes
      - type: move
        from: attributes.stream
        to: attributes["log.iostream"]
        if: "attributes.stream != nil"
      - type: move
        from: attributes.container_name
        to: resource["k8s.container.name"]
        if: "attributes.container_name != nil"
      - type: move
        from: attributes.namespace
        to: resource["k8s.namespace.name"]
        if: "attributes.namespace != nil"
      - type: move
        from: attributes.pod_name
        to: resource["k8s.pod.name"]
        if: "attributes.pod_name != nil"
      - type: move
        from: attributes.restart_count
        to: resource["k8s.container.restart_count"]
        if: "attributes.restart_count != nil"
      - type: move
        from: attributes.uid
        to: resource["k8s.pod.uid"]
        if: "attributes.uid != nil"
      - type: json_parser
        parse_from: attributes.log
        parse_to: attributes._log
        on_error: drop
        if: "attributes.log != nil"
      - type: copy
        from: attributes._log.body
        to: body
        if: "attributes._log.body != nil"
      - type: copy
        from: attributes._log.msg
        to: body
        if: "attributes._log.msg != nil"
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyKubernetesEventsConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.kubernetesEventsConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "logs" false $config) (not (has "k8sobjects" (dig "service" "pipelines" "logs" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append ($config.service.pipelines.logs.receivers | default list) "k8sobjects" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.kubernetesEventsConfig" -}}
receivers:
  k8sobjects:
    objects:
      - name: events
        mode: "watch"
        group: "events.k8s.io"
        exclude_watch_type:
          - "DELETED"
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyBatchProcessorConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.batchProcessorConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "logs" false $config) (not (has "batch" (dig "service" "pipelines" "logs" "processors" list $config))) }}
{{- $_ := set $config.service.pipelines.logs "processors" (prepend ($config.service.pipelines.logs.processors | default list) "batch" | uniq)  }}
{{- end }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "batch" (dig "service" "pipelines" "metrics" "processors" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "processors" (prepend ($config.service.pipelines.metrics.processors | default list) "batch" | uniq)  }}
{{- end }}
{{- if and (dig "service" "pipelines" "traces" false $config) (not (has "batch" (dig "service" "pipelines" "traces" "processors" list $config))) }}
{{- $_ := set $config.service.pipelines.traces "processors" (prepend ($config.service.pipelines.traces.processors | default list) "batch" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.batchProcessorConfig" -}}
processors:
  batch:
    send_batch_size: {{ .presets.batchProcessor.batchSize }}
    timeout: {{ .presets.batchProcessor.timeout }}
    send_batch_max_size: {{ .presets.batchProcessor.maxSize }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyOTLPExporter" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.otlpExporterConfig" .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "logs" false $config) (not (has "otlp" (dig "service" "pipelines" "logs" "exporters" list $config))) }}
{{- $_ := set $config.service.pipelines.logs "exporters" (prepend ($config.service.pipelines.logs.exporters | default list) "otlp" | uniq)  }}
{{- end }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "otlp" (dig "service" "pipelines" "metrics" "exporters" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "exporters" (prepend ($config.service.pipelines.metrics.exporters | default list) "otlp" | uniq)  }}
{{- end }}
{{- if and (dig "service" "pipelines" "traces" false $config) (not (has "otlp" (dig "service" "pipelines" "traces" "exporters" list $config))) }}
{{- $_ := set $config.service.pipelines.traces "exporters" (prepend ($config.service.pipelines.traces.exporters | default list) "otlp" | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.otlpExporterConfig" -}}
exporters:
  otlp:
    endpoint: {{ .presets.otlpExporter.endpoint }}
    timeout:  {{ .presets.otlpExporter.timeout }}
    {{- if .presets.otlpExporter.headers }}
    headers:
      {{- .presets.otlpExporter.headers | toYaml | nindent 6 }}
    {{- end }}
    {{- if .presets.otlpExporter.sending_queue.enabled }}
    sending_queue:
      {{- .presets.otlpExporter.sending_queue | toYaml | nindent 6 }}
    {{- end }}
    {{- if .presets.otlpExporter.retry_on_failure.enabled }}
    retry_on_failure:
      {{- .presets.otlpExporter.retry_on_failure | toYaml | nindent 6 }}
    {{- end }}
{{- end }}
