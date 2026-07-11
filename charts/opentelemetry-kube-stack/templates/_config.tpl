{{/*
Constructs the final config for the given collector

This allows a user to supply a scrape_configs_file. This file is templated and loaded as a yaml array.
If a user has already supplied a prometheus receiver config, the file's config is appended. Finally,
the config is written as YAML.

When no scrape_configs_file is supplied but the targetAllocator is enabled, a minimal prometheus
receiver (with an empty scrape_configs list) is injected if one isn't already defined, so the
target allocator has a receiver to populate.
*/}}
{{- define "opentelemetry-kube-stack.config" -}}
{{- include "opentelemetry-kube-stack.assertPrometheusPresets" . }}
{{- $collector := .collector }}
{{- $config := .collector.config }}
{{- if .collector.scrape_configs_file }}
{{- $config = (include "opentelemetry-kube-stack.collector.appendPrometheusScrapeFile" . | fromYaml) }}
{{- $_ := set $collector "config" $config }}
{{- else if (dig "targetAllocator" "enabled" false .collector) }}
{{- $receivers := (dig "receivers" dict $config) }}
{{- if not (hasKey $receivers "prometheus") }}
{{- $config = (mustMergeOverwrite $config (dict "receivers" (dict "prometheus" (dict "config" (dict "scrape_configs" list))))) }}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "prometheus" (dig "service" "pipelines" "metrics" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append ($config.service.pipelines.metrics.receivers | default list) "prometheus" | uniq) }}
{{- end }}
{{- end }}
{{- if .collector.presets.logsCollection.enabled }}
{{- $_ := set $collector "exclude" (list (printf "/var/log/pods/%s_%s*_*/otc-container/*.log" .namespace (include "opentelemetry-kube-stack.collectorFullname" .))) }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyLogsCollectionConfig" (dict "collector" $collector) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if or .collector.presets.annotationDiscovery.logs.enabled .collector.presets.annotationDiscovery.metrics.enabled }}
{{- $config = (include "opentelemetry-kube-stack.applyAnnotationDiscoveryConfig" (dict "collector" $collector) | fromYaml) }}
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
{{- if .collector.presets.prometheus.nodeExporter.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyPrometheusScrapeConfig" (dict "collector" $collector "configTemplate" "opentelemetry-kube-stack.collector.prometheusNodeExporterConfig" "receiverName" "prometheus/node_exporter") | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.prometheus.cadvisor.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyPrometheusScrapeConfig" (dict "collector" $collector "configTemplate" "opentelemetry-kube-stack.collector.prometheusCadvisorConfig" "receiverName" "prometheus/cadvisor") | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.prometheus.podAnnotations.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyPrometheusScrapeConfig" (dict "collector" $collector "configTemplate" "opentelemetry-kube-stack.collector.prometheusPodAnnotationsConfig" "receiverName" "prometheus/pod_annotations") | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.kubernetesEvents.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyKubernetesEventsConfig" (dict "collector" $collector "namespace" .namespace) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.kubernetesObjects.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyKubernetesObjectsConfig" (dict "collector" $collector "namespace" .namespace) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if .collector.presets.clusterMetrics.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyClusterMetricsConfig" (dict "collector" $collector "namespace" .namespace) | fromYaml) -}}
{{- $_ := set $collector "config" $config }}
{{- end }}
{{- if or .collector.presets.resourceDetection.env.enabled .collector.presets.resourceDetection.eks.enabled .collector.presets.resourceDetection.aks.enabled .collector.presets.resourceDetection.gcp.enabled .collector.presets.resourceDetection.k8sApi.enabled }}
{{- $config = (include "opentelemetry-kube-stack.collector.applyResourceDetectionConfig" (dict "collector" $collector) | fromYaml) -}}
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

{{- define "opentelemetry-kube-stack.applyAnnotationDiscoveryConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.annotationDiscoveryConfig" .collector  | fromYaml) .collector.config }}
{{- $_ := set $config.service "extensions" (append ($config.service.extensions | default list)  "k8s_observer" | uniq)  }}
{{- if .collector.presets.annotationDiscovery.logs.enabled }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append $config.service.pipelines.logs.receivers "receiver_creator/logs" | uniq)  }}
{{- end }}
{{- if .collector.presets.annotationDiscovery.metrics.enabled }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append $config.service.pipelines.metrics.receivers "receiver_creator/metrics" | uniq) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.annotationDiscoveryConfig" -}}
extensions:
  k8s_observer:
    auth_type: serviceAccount
    node: ${env:K8S_NODE_NAME}

receivers:
  {{- if .presets.annotationDiscovery.logs.enabled }}
  receiver_creator/logs:
    watch_observers:
      - k8s_observer
    discovery:
      enabled: true
      default_annotations:
        io.opentelemetry.discovery.logs/enabled: "true"
 {{- end }}
  {{- if .presets.annotationDiscovery.metrics.enabled }}
  receiver_creator/metrics:
    watch_observers:
      - k8s_observer
    discovery:
      enabled: true
  {{- end }}
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
      otel_annotations: true
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
        - service.namespace
        - service.name
        - service.version
        - service.instance.id
      labels:
      - tag_name: k8s.app.instance
        key: app.kubernetes.io/instance
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
            system.cpu.logical.count:
              enabled: true
        load: {}
        memory:
          metrics:
            system.memory.utilization:
              enabled: true
            system.memory.limit:
              enabled: true
        paging:
          metrics:
            system.paging.usage:
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
        system:
          metrics:
            system.uptime:
              enabled: true
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyClusterMetricsConfig" -}}
{{- $electorName := "k8s_cluster" }}
{{- $config := mustMergeOverwrite (include "opentelemetry-kube-stack.collector.clusterMetricsConfig" (dict "collector" .collector "namespace" .namespace "electorName" $electorName) | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has "k8s_cluster" (dig "service" "pipelines" "metrics" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append ($config.service.pipelines.metrics.receivers | default list) "k8s_cluster" | uniq)  }}
{{- $disableLeaderElection := .collector.presets.clusterMetrics.disableLeaderElection }}
{{- if not $disableLeaderElection }}
{{- $_ := set $config.service "extensions" (append ($config.service.extensions | default list) (printf "k8s_leader_elector/%s" $electorName) | uniq)  }}
{{- end }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.clusterMetricsConfig" -}}
{{- $disableLeaderElection := .collector.presets.clusterMetrics.disableLeaderElection}}
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
{{- $disableLeaderElection := .collector.presets.kubernetesEvents.disableLeaderElection }}
{{- if not $disableLeaderElection }}
{{- $_ := set $config.service "extensions" (append ($config.service.extensions | default list) (printf "k8s_leader_elector/%s" $electorName) | uniq)  }}
{{- end }}
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

{{- define "opentelemetry-kube-stack.collector.applyKubernetesObjectsConfig" -}}
{{- $disableLeaderElection := .collector.presets.kubernetesObjects.disableLeaderElection }}
{{- $useLeaderElection := and (eq .collector.mode "daemonset") (not $disableLeaderElection) }}
{{- $electorName := "k8s_objects" }}
{{- $ctx := mustMerge (dict "namespace" .namespace "useLeaderElection" $useLeaderElection "electorName" $electorName) (dict "collector" .collector) }}
{{- $objectsYaml := include "opentelemetry-kube-stack.collector.kubernetesObjectsConfig" $ctx | fromYaml }}
{{- $newObjects := (index $objectsYaml.receivers "k8sobjects").objects }}
{{- $existingObjects := list }}
{{- if .collector.config.receivers }}
{{- if index .collector.config.receivers "k8sobjects" }}
{{- if (index .collector.config.receivers "k8sobjects").objects }}
{{- $existingObjects = (index .collector.config.receivers "k8sobjects").objects }}
{{- end }}
{{- end }}
{{- end }}
{{- $allObjects := concat $newObjects $existingObjects }}
{{- $config := mustMergeOverwrite (dict "service" (dict "pipelines" (dict "logs" (dict "receivers" list)))) $objectsYaml .collector.config }}
{{- $_ := set (index $config.receivers "k8sobjects") "objects" $allObjects }}
{{- $_ := set $config.service.pipelines.logs "receivers" (append $config.service.pipelines.logs.receivers "k8sobjects" | uniq) }}
{{- if $useLeaderElection }}
{{- $configExtensions := mustMergeOverwrite (dict "service" (dict "extensions" list)) $config }}
{{- $_ := set $config.service "extensions" (append $configExtensions.service.extensions (printf "k8s_leader_elector/%s" $electorName) | uniq) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.kubernetesObjectsConfig" -}}
{{- $preset := .collector.presets.kubernetesObjects -}}
{{- if .useLeaderElection }}
{{- include "opentelemetry-kube-stack.collector.leaderElectionConfig" (dict "name" .electorName "leaseName" "k8s.objects.receiver.opentelemetry.io" "leaseNamespace" .namespace) }}
{{- end }}
receivers:
  k8sobjects:
    {{- if .useLeaderElection }}
    k8s_leader_elector: k8s_leader_elector/{{ .electorName }}
    {{- end }}
    objects:
{{- if $preset.core.enabled }}
{{- range list "namespaces" "pods" "nodes" "services" "serviceaccounts" }}
      - name: {{ . }}
        mode: pull
{{- if $preset.watch }}
      - name: {{ . }}
        mode: watch
{{- end }}
{{- end }}
{{- range list "deployments" "replicasets" "daemonsets" "statefulsets" }}
      - name: {{ . }}
        mode: pull
        group: apps
{{- if $preset.watch }}
      - name: {{ . }}
        mode: watch
        group: apps
{{- end }}
{{- end }}
{{- range list "jobs" "cronjobs" }}
      - name: {{ . }}
        mode: pull
        group: batch
{{- if $preset.watch }}
      - name: {{ . }}
        mode: watch
        group: batch
{{- end }}
{{- end }}
{{- end }}
{{- if $preset.rbac.enabled }}
{{- range list "roles" "rolebindings" "clusterroles" "clusterrolebindings" }}
      - name: {{ . }}
        mode: pull
        group: rbac.authorization.k8s.io
{{- if $preset.watch }}
      - name: {{ . }}
        mode: watch
        group: rbac.authorization.k8s.io
{{- end }}
{{- end }}
{{- end }}
{{- if $preset.storage.enabled }}
{{- range list "storageclasses" }}
      - name: {{ . }}
        mode: pull
        group: storage.k8s.io
{{- if $preset.watch }}
      - name: {{ . }}
        mode: watch
        group: storage.k8s.io
{{- end }}
{{- end }}
{{- range list "persistentvolumes" "persistentvolumeclaims" }}
      - name: {{ . }}
        mode: pull
{{- if $preset.watch }}
      - name: {{ . }}
        mode: watch
{{- end }}
{{- end }}
{{- end }}
{{- if $preset.networking.enabled }}
{{- range list "ingresses" "networkpolicies" }}
      - name: {{ . }}
        mode: pull
        group: networking.k8s.io
{{- if $preset.watch }}
      - name: {{ . }}
        mode: watch
        group: networking.k8s.io
{{- end }}
{{- end }}
{{- end }}
{{- if $preset.autoscaling.enabled }}
      - name: horizontalpodautoscalers
        mode: pull
        group: autoscaling
{{- if $preset.watch }}
      - name: horizontalpodautoscalers
        mode: watch
        group: autoscaling
{{- end }}
{{- if $preset.autoscaling.vpa.enabled }}
      - name: verticalpodautoscalers
        mode: pull
        group: autoscaling.k8s.io
{{- if $preset.watch }}
      - name: verticalpodautoscalers
        mode: watch
        group: autoscaling.k8s.io
{{- end }}
{{- end }}
{{- end }}
{{- if $preset.policy.enabled }}
      - name: poddisruptionbudgets
        mode: pull
        group: policy
{{- if $preset.watch }}
      - name: poddisruptionbudgets
        mode: watch
        group: policy
{{- end }}
{{- end }}
{{- if $preset.apiExtensions.enabled }}
      - name: customresourcedefinitions
        mode: pull
        group: apiextensions.k8s.io
{{- if $preset.watch }}
      - name: customresourcedefinitions
        mode: watch
        group: apiextensions.k8s.io
{{- end }}
{{- end }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.applyResourceDetectionConfig" -}}

{{- $config := .collector.config }}
{{- $processors := get $config "processors" | default dict }}
{{- $resourceDetectionProcessor := get $processors "resourcedetection/env" | default dict }}
{{- $detectors := get $resourceDetectionProcessor "detectors" | default list }}

{{- if .collector.presets.resourceDetection.env.enabled }}
{{- $detectors = append $detectors "env" | uniq }}
{{- end }}

{{- if .collector.presets.resourceDetection.aks.enabled }}
{{- $aksResourceDetectionProcessor := include "opentelemetry-kube-stack.collector.resourceDetectionAksDetectorConfig" . | fromYaml }}
{{- $resourceDetectionProcessor = mustMergeOverwrite $resourceDetectionProcessor $aksResourceDetectionProcessor }}
{{- $detectors = append $detectors "aks" | uniq }}
{{- end }}

{{- if .collector.presets.resourceDetection.eks.enabled }}
{{- $eksResourceDetectionProcessor := include "opentelemetry-kube-stack.collector.resourceDetectionEksDetectorConfig" . | fromYaml }}
{{- $resourceDetectionProcessor = mustMergeOverwrite $resourceDetectionProcessor $eksResourceDetectionProcessor }}
{{- $detectors = append $detectors "eks" | uniq }}
{{- end }}

{{- if .collector.presets.resourceDetection.gcp.enabled }}
{{- $gcpResourceDetectionProcessor := include "opentelemetry-kube-stack.collector.resourceDetectionGcpDetectorConfig" . | fromYaml }}
{{- $resourceDetectionProcessor = mustMergeOverwrite $resourceDetectionProcessor $gcpResourceDetectionProcessor }}
{{- $detectors = append $detectors "gcp" | uniq }}
{{- end }}

{{- if .collector.presets.resourceDetection.k8sApi.enabled }}
{{- $k8sApiResourceDetectionProcessor := include "opentelemetry-kube-stack.collector.resourceDetectionK8sApiDetectorConfig" . | fromYaml }}
{{- $resourceDetectionProcessor = mustMergeOverwrite $resourceDetectionProcessor $k8sApiResourceDetectionProcessor }}
{{- $detectors = append $detectors "k8s_api" | uniq }}
{{- end }}
{{- $_ := set $resourceDetectionProcessor "detectors" $detectors }}

{{- $_ := set $processors "resourcedetection/env" $resourceDetectionProcessor }}
{{- $_ := set $config "processors" $processors }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.resourceDetectionEksDetectorConfig" -}}
timeout: 15s
eks:
  # K8S_NODE_NAME is configured by the collector deployment, no need to overwrite `node_from_env_var`
  resource_attributes:
    k8s.cluster.name:
      enabled: true
{{- end -}}

{{- define "opentelemetry-kube-stack.collector.resourceDetectionAksDetectorConfig" -}}
aks:
  resource_attributes:
    k8s.cluster.name:
      enabled: true
{{- end -}}

{{- define "opentelemetry-kube-stack.collector.resourceDetectionGcpDetectorConfig" -}}
gcp:
  resource_attributes:
    k8s.cluster.name:
      enabled: true
{{- end -}}

{{- define "opentelemetry-kube-stack.collector.resourceDetectionK8sApiDetectorConfig" -}}
k8s_api:
  resource_attributes:
    k8s.cluster.uid:
      enabled: true
{{- end -}}

{{/*
Validates the `presets.prometheus.*` family of presets:
  * mutually exclusive with `scrape_configs_file` — they are a replacement, not
    an addition. Enabling both would cause duplicate scrapes (the default
    daemon_scrape_configs.yaml already has node-exporter / kubelet-cadvisor /
    kubernetes-pods jobs).
  * require the collector to run in `daemonset` mode — the scrape configs use
    the OTEL_K8S_NODE_IP / OTEL_K8S_NODE_NAME env vars and kubernetes_sd
    field selectors keyed on the local node, which are only meaningful when
    a collector pod is scheduled per node.
*/}}
{{- define "opentelemetry-kube-stack.assertPrometheusPresets" -}}
{{- $prom := .collector.presets.prometheus }}
{{- $enabled := list }}
{{- if $prom.nodeExporter.enabled }}{{- $enabled = append $enabled "nodeExporter" }}{{- end }}
{{- if $prom.cadvisor.enabled }}{{- $enabled = append $enabled "cadvisor" }}{{- end }}
{{- if $prom.podAnnotations.enabled }}{{- $enabled = append $enabled "podAnnotations" }}{{- end }}
{{- if $enabled }}
{{- $collectorName := .collector.suffix | default "unnamed" }}
{{- $enabledList := join ", " $enabled }}
{{- if .collector.scrape_configs_file }}
{{- fail (printf "collector %q: presets.prometheus.{%s} are a replacement for `scrape_configs_file` (the chart default is `daemon_scrape_configs.yaml`). Both are configured: scrape_configs_file=%q. Choose one — either keep `scrape_configs_file` and disable the listed presets, or keep the presets and set `scrape_configs_file: \"\"`." $collectorName $enabledList .collector.scrape_configs_file) }}
{{- end }}
{{- $mode := .collector.mode | default "deployment" }}
{{- if ne $mode "daemonset" }}
{{- fail (printf "collector %q: presets.prometheus.{%s} require `mode: daemonset` (current mode: %q). The scrape targets reference ${OTEL_K8S_NODE_IP} / ${OTEL_K8S_NODE_NAME}, which the OpenTelemetry Operator only injects on daemonset collector pods." $collectorName $enabledList $mode) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Shared apply helper for the `presets.prometheus.*` family. Merges the named
scrape-config template into the collector config and appends the receiver to
the metrics pipeline. Args:
  collector     - the collector dict
  configTemplate - full name of the scrape-config template to include
  receiverName  - receiver key to append to service.pipelines.metrics.receivers
*/}}
{{- define "opentelemetry-kube-stack.collector.applyPrometheusScrapeConfig" -}}
{{- $config := mustMergeOverwrite (include .configTemplate .collector | fromYaml) .collector.config }}
{{- if and (dig "service" "pipelines" "metrics" false $config) (not (has .receiverName (dig "service" "pipelines" "metrics" "receivers" list $config))) }}
{{- $_ := set $config.service.pipelines.metrics "receivers" (append ($config.service.pipelines.metrics.receivers | default list) .receiverName | uniq)  }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.prometheusNodeExporterConfig" -}}
{{- $cfg := .presets.prometheus.nodeExporter }}
receivers:
  prometheus/node_exporter:
    config:
      scrape_configs:
        - job_name: node-exporter
          scrape_interval: {{ $cfg.scrapeInterval }}
          scrape_timeout: {{ $cfg.scrapeTimeout }}
          static_configs:
            - targets:
                - ${env:OTEL_K8S_NODE_IP}:{{ $cfg.port }}
          relabel_configs:
            - target_label: node
              replacement: ${env:OTEL_K8S_NODE_NAME}
{{- end }}

{{- define "opentelemetry-kube-stack.collector.prometheusCadvisorConfig" -}}
{{- $cfg := .presets.prometheus.cadvisor }}
receivers:
  prometheus/cadvisor:
    config:
      scrape_configs:
        - job_name: kubelet
          scheme: https
          metrics_path: /metrics/cadvisor
          scrape_interval: {{ $cfg.scrapeInterval }}
          scrape_timeout: {{ $cfg.scrapeTimeout }}
          authorization:
            type: Bearer
            credentials_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
            insecure_skip_verify: true
          static_configs:
            - targets:
                - ${env:OTEL_K8S_NODE_IP}:{{ $cfg.port }}
          relabel_configs:
            - target_label: node
              replacement: ${env:OTEL_K8S_NODE_NAME}
          metric_relabel_configs:
            # Drop the highest-cardinality / lowest-value cAdvisor series. Mirrors the
            # `metric_relabel_configs` used by the kubelet job in daemon_scrape_configs.yaml.
            - source_labels: [__name__]
              regex: container_cpu_(load_average_10s|system_seconds_total|user_seconds_total)
              action: drop
            - source_labels: [__name__]
              regex: container_fs_(io_current|reads_merged_total|sector_reads_total|sector_writes_total|writes_merged_total)
              action: drop
            - source_labels: [__name__]
              regex: container_memory_(mapped_file|swap)
              action: drop
            - source_labels: [__name__]
              regex: container_(file_descriptors|tasks_state|threads_max)
              action: drop
            - source_labels: [__name__]
              regex: container_spec.*
              action: drop
            # Drop series where the cgroup id is set but the pod label is empty
            # (non-pod cgroups like system.slice and the kubelet's own resources).
            - source_labels: [id, pod]
              regex: .+;
              action: drop
{{- end }}

{{- define "opentelemetry-kube-stack.collector.prometheusPodAnnotationsConfig" -}}
{{- $cfg := .presets.prometheus.podAnnotations }}
receivers:
  prometheus/pod_annotations:
    config:
      scrape_configs:
        - job_name: kubernetes-pods
          scrape_interval: {{ $cfg.scrapeInterval }}
          scrape_timeout: {{ $cfg.scrapeTimeout }}
          kubernetes_sd_configs:
            - role: pod
              selectors:
                - role: pod
                  # Only scrape data from pods running on the same node as the collector,
                  # and skip the OpenTelemetry collector's own pods to avoid self-scrape loops.
                  field: "spec.nodeName=${env:OTEL_K8S_NODE_NAME}"
                  label: "app.kubernetes.io/component!=opentelemetry-collector"
          relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: true
            - source_labels:
                [__meta_kubernetes_pod_annotation_prometheus_io_scrape_slow]
              action: drop
              regex: true
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scheme]
              action: replace
              regex: (https?)
              target_label: __scheme__
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
            - source_labels:
                [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              # NOTE: otel collector uses env var replacement. $$ is used as a literal $.
              replacement: $$1:$$2
              target_label: __address__
            - action: labelmap
              regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)
              replacement: __param_$$1
            # Emit Prometheus-style Kubernetes labels: namespace, pod, node, and all pod labels
            # mapped via __meta_kubernetes_pod_label_*.
            - action: labelmap
              regex: __meta_kubernetes_pod_label_(.+)
            - source_labels: [__meta_kubernetes_namespace]
              action: replace
              target_label: namespace
            - source_labels: [__meta_kubernetes_pod_name]
              action: replace
              target_label: pod
            - source_labels: [__meta_kubernetes_pod_node_name]
              action: replace
              target_label: node
            - source_labels: [__meta_kubernetes_pod_phase]
              regex: Pending|Succeeded|Failed|Completed
              action: drop
            - action: replace
              source_labels: [__meta_kubernetes_pod_label_app_kubernetes_io_name]
              target_label: job
{{- end }}
