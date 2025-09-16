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
{{- $_ := set $collector "exclude" (list (printf "/var/log/pods/%s_%s*_*/otc-container/*.log" .namespace (include "opentelemetry-kube-stack.collectorFullname" .))) }}
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
{{- $config = (include "opentelemetry-kube-stack.collector.applyKubernetesEventsConfig" (dict "collector" $collector "namespace" .namespace) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.clusterMetrics.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyClusterMetricsConfig" (dict "collector" $collector "namespace" .namespace) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- tpl (toYaml $collector.config) . | nindent 4 }}
{{- end }}

{{/*
This helper allows a user to load in an external scrape configs file directly from prometheus.
The helper will load and then append the scrape configs list to an existing prometheus scraper.
If no prometheus configuration is present, the prometheus configuration is added.

This helper ultimately assists users in getting started with Kubernetes infra metrics from scratch
OR helps them easily port prometheus to the otel-kube-stack chart with no changes to their prometheus config.
*/}}
{{- define "opentelemetry-kube-stack.collector.appendPrometheusScrapeFile" -}}
{{- $loaded_file := (.Files.Get .collector.scrape_configs_file) }}
{{- $loaded_config := (fromYamlArray (tpl $loaded_file .)) }}
{{- $prom_override := (dict "receivers" (dict "prometheus" (dict "config" (dict "scrape_configs" $loaded_config)))) }}
{{- if (dig "receivers" "prometheus" "config" "scrape_configs" false .collector.config) }}
{{- $merged_prom_scrape_configs := (concat .collector.config.receivers.prometheus.config.scrape_configs $loaded_config) }}
{{- $prom_override = (dict "receivers" (dict "prometheus" (dict "config" (dict "scrape_configs" $merged_prom_scrape_configs)))) }}
{{- end }}
{{- if and (dig "service" "pipelines" "metrics" false .collector.config) (not (has "prometheus" (dig "service" "pipelines" "metrics" "receivers" list .collector.config))) }}
{{- $_ := set .collector.config.service.pipelines.metrics "receivers" (prepend (.collector.config.service.pipelines.metrics.receivers | default list) "prometheus" | uniq)  }}
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
      node_from_env_var: OTEL_K8S_NODE_NAME
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
        load: {}
        memory:
          metrics:
            system.memory.utilization:
                enabled: true
        disk: {}
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
        network: {}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyClusterMetricsConfig" -}}
{{- $electorName := "k8s_cluster" }}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.clusterMetricsConfig" (dict "collector" .collector "namespace" .namespace "electorName" $electorName) | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "k8s_cluster" (dig "service" "pipelines" "metrics" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append ($config.service.pipelines.metrics.receivers | default list) "k8s_cluster" | uniq)  }}
{{- $_ := set $config.service "extensions" (append ($config.service.extensions | default list) (printf "k8s_leader_elector/%s" $electorName) | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.clusterMetricsConfig" -}}
{{- $disableLeaderElection := .collector.presets.kubernetesEvents.disableLeaderElection}}
{{- if not $disableLeaderElection}}
{{- include "opentelemetry-kube-stack.collector.leaderElectionConfig" (dict "name" .electorName "leaseName" "k8s.cluster.receiver.opentelemetry.io" "leaseNamespace" .namespace)}}    
{{- end}}
receivers:
  k8s_cluster:
    {{- if not $disableLeaderElection}}
    k8s_leader_elector: k8s_leader_elector/{{ .electorName }}
    {{- end}}
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
        container.cpu.usage:
            enabled: true
        k8s.node.cpu.usage:
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
    {{- if .presets.logsCollection.includeCollectorLogs }}
    exclude: []
    {{- else }}
    # Exclude collector container's logs. The file format is /var/log/pods/<namespace_name>_<pod_name>_<pod_uid>/<container_name>/<run_id>.log
    exclude:
    {{- toYaml .exclude | nindent 4 }}
    {{- end }}
    start_at: end
    retry_on_failure:
        enabled: true
    {{- if .presets.logsCollection.storeCheckpoints}}
    storage: file_storage
    {{- end }}
    include_file_path: true
    include_file_name: false
    operators:
      # parse container logs
      - type: container
        id: container-parser
        max_log_size: {{ .presets.logsCollection.maxRecombineLogSize }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyKubernetesEventsConfig" -}}
{{- $electorName := "k8s_objects" }}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.kubernetesEventsConfig" (dict "collector" .collector "namespace" .namespace "electorName" $electorName) | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "logs" false $config) (not (has "k8sobjects" (dig "service" "pipelines" "logs" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append ($config.service.pipelines.logs.receivers | default list) "k8sobjects" | uniq)  }}
{{- $_ := set $config.service "extensions" (append ($config.service.extensions | default list) (printf "k8s_leader_elector/%s" $electorName) | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.kubernetesEventsConfig" -}}
{{- $disableLeaderElection := .collector.presets.kubernetesEvents.disableLeaderElection}}
{{- if not $disableLeaderElection}}
{{- include "opentelemetry-kube-stack.collector.leaderElectionConfig" (dict "name" .electorName "leaseName" "k8s.objects.receiver.opentelemetry.io" "leaseNamespace" .namespace)}}    
{{- end}}
receivers:
  k8sobjects:
    {{- if not $disableLeaderElection}}
    k8s_leader_elector: k8s_leader_elector/{{ .electorName }}
    {{- end}}
    objects:
      - name: events
        mode: "watch"
        group: "events.k8s.io"
        exclude_watch_type:
          - "DELETED"
{{- end }}

{{- define "opentelemetry-kube-stack.collector.leaderElectionConfig" -}}
extensions:
  k8s_leader_elector/{{ .name }}:
    auth_type: serviceAccount
    lease_name: {{ .leaseName }}
    lease_namespace: {{ .leaseNamespace }}
{{- end }}