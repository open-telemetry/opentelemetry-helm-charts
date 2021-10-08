{{- $isDaemonset := eq .Values.mode "daemonset" -}}
{{- $isDeployment := eq .Values.mode "deployment" -}}
{{- if or $isDaemonset $isDeployment -}}
{{- fail (print "value for mode (.Values.mode) needs to be either daemonset or deployment, it's" .Values.mode) }}
{{- end -}}


{{/* Merge user supplied top-level config into all the presets */}}
{{- define "opentelemetry-collector.config" -}}
{{- $config := deepCopy .Values.config }}
{{- $config := include "opentelemetry-collector.containerLogsConfig" . | fromYaml | mustMergeOverwrite $config }}
{{- $config := include "opentelemetry-collector.hostMetricsConfig" . | fromYaml | mustMergeOverwrite $config }}
{{- $config := include "opentelemetry-collector.memoryLimiterConfig" . | fromYaml | mustMergeOverwrite $config }}
{{- $config | toYaml }}
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

{{- define "opentelemetry-collector.hostMetricsConfig" -}}
{{- $isDaemonset := eq .Values.mode "daemonset" -}}
{{- if (and .Values.enabledConfigPresets.hostMetrics $isDaemonset) }}
receivers:
  hostmetrics/k8s:
    scrapers:
      cpu:
      disk:
      filesystem:
{{- end }}
{{- end }}

{{/* Memory limiter configuration for OpenTelemetry Collector based on k8s resource limits. */}}
{{- define "opentelemetry-collector.memoryLimiterConfig" -}}
{{- if .Values.enabledConfigPresets.memoryLimiter }}
processors:
  memory_limiter/k8s:
    # check_interval is the time between measurements of memory usage.
    check_interval: 5s

    # By default limit_mib is set to 80% of ".Values.resources.limits.memory"
    limit_mib: {{ include "opentelemetry-collector.getMemLimitMib" .Values.resources.limits.memory }}

    # by default spike_limit_mib is set to 25% of ".values.resources.limits.memory"
    spike_limit_mib: {{ include "opentelemetry-collector.getMemSpikeLimitMib" .Values.resources.limits.memory }}

    # By default ballast_size_mib is set to 40% of ".Values.resources.limits.memory"
    ballast_size_mib: {{ include "opentelemetry-collector.getMemBallastSizeMib" .Values.resources.limits.memory }}
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.containerLogsConfig" -}}
{{- $isDaemonset := eq .Values.mode "daemonset" -}}
{{- if (and .Values.enabledConfigPresets.containerLogs $isDaemonset) }}
receivers:
  filelog/k8s:
    include: [ /var/log/pods/*/*/*.log ]
    # Exclude collector container's logs. The file format is /var/log/pods/<namespace_name>_<pod_name>_<pod_uid>/<container_name>/<run_id>.log
    exclude: [ /var/log/pods/{{ .Release.Namespace }}_{{ include "opentelemetry-collector.fullname" . }}*_*/{{ .Chart.Name }}/*.log ]
    start_at: beginning
    include_file_path: true
    include_file_name: false
    operators:
      # Find out which format is used by kubernetes
      - type: router
        id: get-format
        routes:
          - output: parser-docker
            expr: '$$body matches "^\\{"'
          - output: parser-crio
            expr: '$$body matches "^[^ Z]+ "'
          - output: parser-containerd
            expr: '$$body matches "^[^ Z]+Z"'
      # Parse CRI-O format
      - type: regex_parser
        id: parser-crio
        regex: '^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) (?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout_type: gotime
          layout: '2006-01-02T15:04:05.000000000-07:00'
      # Parse CRI-Containerd format
      - type: regex_parser
        id: parser-containerd
        regex: '^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) (?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      # Parse Docker format
      - type: json_parser
        id: parser-docker
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      # Extract metadata from file path
      - type: regex_parser
        id: extract_metadata_from_filepath
        regex: '^.*\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[a-f0-9\-]{36})\/(?P<container_name>[^\._]+)\/(?P<run_id>\d+)\.log$'
        parse_from: $$attributes.file_path
      # Move out attributes to Attributes
      - type: metadata
        labels:
          stream: 'EXPR($.stream)'
          k8s.container.name: 'EXPR($.container_name)'
          k8s.namespace.name: 'EXPR($.namespace)'
          k8s.pod.name: 'EXPR($.pod_name)'
          run_id: 'EXPR($.run_id)'
          k8s.pod.uid: 'EXPR($.uid)'
      # Clean up log body
      - type: restructure
        id: clean-up-log-body
        ops:
          - move:
              from: log
              to: $
{{- end }}
{{- end }}
