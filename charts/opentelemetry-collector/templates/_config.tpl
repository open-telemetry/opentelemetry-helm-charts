{{/*
Default memory limiter configuration for OpenTelemetry Collector based on k8s resource limits.
*/}}
{{- define "opentelemetry-collector.memoryLimiter" -}}
processors:
  memory_limiter:
    # check_interval is the time between measurements of memory usage.
    check_interval: 5s

    # By default limit_mib is set to 80% of ".Values.resources.limits.memory"
    limit_mib: {{ include "opentelemetry-collector.getMemLimitMib" .Values.resources.limits.memory }}

    # By default spike_limit_mib is set to 25% of ".Values.resources.limits.memory"
    spike_limit_mib: {{ include "opentelemetry-collector.getMemSpikeLimitMib" .Values.resources.limits.memory }}

    # By default ballast_size_mib is set to 40% of ".Values.resources.limits.memory"
    ballast_size_mib: {{ include "opentelemetry-collector.getMemBallastSizeMib" .Values.resources.limits.memory }}
{{- end }}

{{/*
Merge user supplied top-level (not particular to standalone or agent) config into memory limiter config.
*/}}
{{- define "opentelemetry-collector.baseConfig" -}}
{{- $config := include "opentelemetry-collector.memoryLimiter" . | fromYaml  -}}
{{- .Values.config | mustMergeOverwrite $config  | toYaml }}
{{- end }}

{{/*
Build config file for agent OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.agentCollectorConfig" -}}
{{- $values := deepCopy .Values.agentCollector | mustMergeOverwrite (deepCopy .Values)  }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- $config := include "opentelemetry-collector.agent.containerLogsConfig" $data | fromYaml | mustMergeOverwrite $config }}
{{- $config := include "opentelemetry-collector.agentConfigOverride" $data | fromYaml | mustMergeOverwrite $config }}
{{- .Values.agentCollector.configOverride | mustMergeOverwrite $config | toYaml }}
{{- end }}

{{/*
Build config file for standalone OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.standaloneCollectorConfig" -}}
{{- $values := deepCopy .Values.standaloneCollector | mustMergeOverwrite (deepCopy .Values)  }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.baseConfig" $data | fromYaml }}
{{- .Values.standaloneCollector.configOverride | mustMergeOverwrite $config | toYaml }}
{{- end }}

{{/*
Convert memory value from resources.limit to numeric value in MiB to be used by otel memory_limiter processor.
*/}}
{{- define "opentelemetry-collector.convertMemToMib" -}}
{{- $mem := lower . -}}
{{- if hasSuffix "e" $mem -}}
{{- trimSuffix "e" $mem | atoi | mul 1000 | mul 1000 | mul 1000 | mul 1000 -}}
{{- else if hasSuffix "ei" $mem -}}
{{- trimSuffix "ei" $mem | atoi | mul 1024 | mul 1024 | mul 1024 | mul 1024 -}}
{{- else if hasSuffix "p" $mem -}}
{{- trimSuffix "p" $mem | atoi | mul 1000 | mul 1000 | mul 1000 -}}
{{- else if hasSuffix "pi" $mem -}}
{{- trimSuffix "pi" $mem | atoi | mul 1024 | mul 1024 | mul 1024 -}}
{{- else if hasSuffix "t" $mem -}}
{{- trimSuffix "t" $mem | atoi | mul 1000 | mul 1000 -}}
{{- else if hasSuffix "ti" $mem -}}
{{- trimSuffix "ti" $mem | atoi | mul 1024 | mul 1024 -}}
{{- else if hasSuffix "g" $mem -}}
{{- trimSuffix "g" $mem | atoi | mul 1000 -}}
{{- else if hasSuffix "gi" $mem -}}
{{- trimSuffix "gi" $mem | atoi | mul 1024 -}}
{{- else if hasSuffix "m" $mem -}}
{{- div (trimSuffix "m" $mem | atoi | mul 1000) 1024 -}}
{{- else if hasSuffix "mi" $mem -}}
{{- trimSuffix "mi" $mem | atoi -}}
{{- else if hasSuffix "k" $mem -}}
{{- div (trimSuffix "k" $mem | atoi) 1000 -}}
{{- else if hasSuffix "ki" $mem -}}
{{- div (trimSuffix "ki" $mem | atoi) 1024 -}}
{{- else -}}
{{- div (div ($mem | atoi) 1024) 1024 -}}
{{- end -}}
{{- end -}}

{{/*
Get otel memory_limiter limit_mib value based on 80% of resources.memory.limit.
*/}}
{{- define "opentelemetry-collector.getMemLimitMib" -}}
{{- div (mul (include "opentelemetry-collector.convertMemToMib" .) 80) 100 }}
{{- end -}}

{{/*
Get otel memory_limiter spike_limit_mib value based on 25% of resources.memory.limit.
*/}}
{{- define "opentelemetry-collector.getMemSpikeLimitMib" -}}
{{- div (mul (include "opentelemetry-collector.convertMemToMib" .) 25) 100 }}
{{- end -}}

{{/*
Get otel memory_limiter ballast_size_mib value based on 40% of resources.memory.limit.
*/}}
{{- define "opentelemetry-collector.getMemBallastSizeMib" }}
{{- div (mul (include "opentelemetry-collector.convertMemToMib" .) 40) 100 }}
{{- end -}}

{{/*
Default config override for agent collector deamonset
*/}}
{{- define "opentelemetry-collector.agentConfigOverride" -}}
{{- if .Values.standaloneCollector.enabled }}
exporters:
  otlp:
    endpoint: {{ include "opentelemetry-collector.fullname" . }}:4317
    insecure: true
{{- end }}

{{- if .Values.standaloneCollector.enabled }}
service:
  pipelines:
    metrics:
      exporters: [otlp]
    traces:
      exporters: [otlp]
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.agent.containerLogsConfig" -}}
{{- if .Values.agentCollector.containerLogs.enabled }}
receivers:
  filelog:
    include: [ /var/log/pods/*/*/*.log ]
    {{- if not .Values.agentCollector.containerLogs.includeAgentLogs }}
    exclude: [ /var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}-agent-*_*/{{ .Chart.Name }}/*.log ]
    {{- end }}
    start_at: beginning
    include_file_path: true
    include_file_name: false
    operators:
      {{- if eq .Values.agentCollector.containerLogs.containerRunTime "cri-o" }}
      # Parse CRI-O format
      - type: regex_parser
        id: parser-crio
        regex: '^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) (?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout_type: gotime
          layout: '2006-01-02T15:04:05.000000000-07:00'
      {{- end }}
      {{- if eq .Values.agentCollector.containerLogs.containerRunTime "containerd" }}
      # Parse CRI-Containerd format
      - type: regex_parser
        id: parser-containerd
        regex: '^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) (?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      {{- end }}
      # Parse Docker format
      {{- if eq .Values.agentCollector.containerLogs.containerRunTime "docker" }}
      - type: json_parser
        id: parser-docker
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      {{- end }}
      # Extract metadata from file path
      - type: regex_parser
        id: extract_metadata_from_filepath
        regex: '^\/var\/log\/pods\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[^\/]+)\/(?P<container_name>[^\._]+)\/(?P<run_id>\d+)\.log$'
        parse_from: $$labels.file_path
      # Move out attributes to Attributes
      - type: metadata
        labels:
          stream: 'EXPR($.stream)'
          k8s.container.name: 'EXPR($.container_name)'
          k8s.namespace.name: 'EXPR($.namespace)'
          k8s.pod.name: 'EXPR($.pod_name)'
          run_id: 'EXPR($.run_id)'
          k8s.pod.uid: 'EXPR($.uid)'
      # Clean up log record
      - type: restructure
        id: clean-up-log-record
        ops:
          - remove: logtag
          - remove: stream
          - remove: container_name
          - remove: namespace
          - remove: pod_name
          - remove: run_id
          - remove: uid
      # Enrich log with k8s metadata
      # - type: k8s_metadata_decorator
      #   id: k8s-metadata-enrichment
      #   namespace_field: k8s.namespace.name
      #   pod_name_field: k8s.pod.name
      #   cache_ttl: 10m
      #   timeout: 10s
      # TODO: multiline concatenate per container
      #- type: file
processors:
  k8s_tagger:
    passthrough: false
    auth_type: "kubeConfig"
    extract:
      metadata:
        # extract the following well-known metadata fields
        - podName
        - podUID
        - deployment
        - cluster
        - namespace
        - node
        - startTime
    filter:
      node_from_env_var: KUBE_NODE_NAME
service:
  pipelines:
    logs:
      receivers:
        - filelog
      processors:
        - k8s_tagger
      exporters:
        - logging
{{- end }}
{{- end }}
