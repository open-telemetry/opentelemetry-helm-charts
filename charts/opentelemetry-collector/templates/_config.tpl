{{- define "opentelemetry-collector.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}


{{/*
Generate preset base config.
*/}}
{{- define "opentelemetry-collector.presets.baseConfig" -}}
exporters:
    logging: {}
extensions:
  health_check: {}
  {{- if eq .Values.mode "daemonset" }}
  memory_ballast:
    size_mib: {{ include "opentelemetry-collector.getMemBallastSizeMib" .Values.resources.limits.memory | quote }}
  {{- else }}
  memory_ballast: {}
  {{- end }}
processors:
    batch:  {}
    memory_limiter:
      # check_interval is the time between measurements of memory usage.
      check_interval: 5s
      # By default limit_mib is set to 80% of ".Values.resources.limits.memory"
      limit_mib: {{ include "opentelemetry-collector.getMemLimitMib" .Values.resources.limits.memory }}
      # By default spike_limit_mib is set to 25% of ".Values.resources.limits.memory"
      spike_limit_mib: {{ include "opentelemetry-collector.getMemSpikeLimitMib" .Values.resources.limits.memory }}
service:
  telemetry:
    metrics:
      address: 0.0.0.0:8888
  extensions:
    - health_check
    - memory_ballast
{{- end }}

{{/*
Generate preset traces config.
*/}}
{{- define "opentelemetry-collector.presets.tracesConfig" -}}
{{- if .Values.presets.traces.enabled }}
receivers:
  jaeger:
    protocols:
      grpc:
        endpoint: 0.0.0.0:14250
      thrift_http:
        endpoint: 0.0.0.0:14268
      thrift_compact:
        endpoint: 0.0.0.0:6831
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  zipkin:
    endpoint: 0.0.0.0:9411
service:
  pipelines:
    traces:
      exporters:
        - logging
      processors:
        - memory_limiter
        - batch
      receivers:
        - otlp
        - jaeger
        - zipkin
{{- end }}
{{- end }}

{{/*
Generate preset metrics config.
*/}}
{{- define "opentelemetry-collector.presets.metricsConfig" -}}
{{- if .Values.presets.metrics.enabled }}
receivers:
  {{- if .Values.presets.metrics.hostMetrics.enabled }}
  hostmetrics:
    scrapers:
      cpu:
      load:
      memory:
      disk:
  {{- end }}
  prometheus:
    config:
      {{- if .Values.presets.metrics.selfScraping.enabled }}
      scrape_configs:
        - job_name: opentelemetry-collector
          scrape_interval: 10s
          static_configs:
            - targets:
                - ${MY_POD_IP}:8888
      {{- end }}
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
service:
  pipelines:
    metrics:
      exporters:
        - logging
      processors:
        - memory_limiter
        - batch
      receivers:
        - otlp
        - prometheus
        {{- if .Values.presets.metrics.hostMetrics.enabled }}
        - hostmetrics
        {{- end }}
{{- end }}
{{- end }}

{{/*
Generate preset logs config.
*/}}
{{- define "opentelemetry-collector.presets.logsConfig" -}}
{{- if .Values.presets.logs.enabled }}
receivers:
  {{- if .Values.presets.logs.containerLogs.enabled }}
  filelog:
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
            expr: 'body matches "^\\{"'
          - output: parser-crio
            expr: 'body matches "^[^ Z]+ "'
          - output: parser-containerd
            expr: 'body matches "^[^ Z]+Z"'
      # Parse CRI-O format
      - type: regex_parser
        id: parser-crio
        regex: '^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: attributes.time
          layout_type: gotime
          layout: '2006-01-02T15:04:05.000000000-07:00'
      # Parse CRI-Containerd format
      - type: regex_parser
        id: parser-containerd
        regex: '^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$'
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: attributes.time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      # Parse Docker format
      - type: json_parser
        id: parser-docker
        output: extract_metadata_from_filepath
        timestamp:
          parse_from: attributes.time
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
      # Extract metadata from file path
      - type: regex_parser
        id: extract_metadata_from_filepath
        regex: '^.*\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[a-f0-9\-]{36})\/(?P<container_name>[^\._]+)\/(?P<restart_count>\d+)\.log$'
        parse_from: attributes["log.file.path"]
      # Rename attributes
      - type: move
        from: attributes.stream
        to: attributes["log.iostream"]
      - type: move
        from: attributes.container_name
        to: attributes["k8s.container.name"]
      - type: move
        from: attributes.namespace
        to: attributes["k8s.namespace.name"]
      - type: move
        from: attributes.pod_name
        to: attributes["k8s.pod.name"]
      - type: move
        from: attributes.restart_count
        to: attributes["k8s.container.restart_count"]
      - type: move
        from: attributes.uid
        to: attributes["k8s.pod.uid"]
      # Clean up log body
      - type: move
        from: attributes.log
        to: body
{{- end }}
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
service:
  pipelines:
    logs:
      exporters:
        - logging
      processors:
        - memory_limiter
        - batch
      receivers:
        - otlp
        {{- if or .Values.presets.logs.containerLogs.enabled }}
        - filelog
        {{- end }}
{{- end }}
{{- end }}

{{/*
Build config file for daemonset OpenTelemetry Collector
*/}}
{{- define "opentelemetry-collector.config" -}}
{{- $values := deepCopy .Values }}
{{- $data := dict "Values" $values | mustMergeOverwrite (deepCopy .) }}
{{- $config := include "opentelemetry-collector.presets.baseConfig" $data | fromYaml }}
{{- $config := include "opentelemetry-collector.presets.tracesConfig" $data | fromYaml | mustMergeOverwrite $config }}
{{- $config := include "opentelemetry-collector.presets.metricsConfig" $data | fromYaml | mustMergeOverwrite $config }}
{{- $config := include "opentelemetry-collector.presets.logsConfig" $data | fromYaml | mustMergeOverwrite $config }}
{{- $config := mustMergeOverwrite $config .Values.config }}
{{- include "opentelemetry-collector.removeNullValues" (get $config "receivers") }}
{{- include "opentelemetry-collector.removeNullValues" (get $config "processors") }}
{{- include "opentelemetry-collector.removeNullValues" (get $config "exporters") }}
{{- include "opentelemetry-collector.removeNullValues" (get (get $config "service") "pipelines") }}
{{- $config | toYaml }}
{{- end }}

{{/*
Remove null values
*/}}
{{- define "opentelemetry-collector.removeNullValues" -}}
{{- $dict := .}}
{{- range $k, $v := (deepCopy .) }}
  {{- if eq ($v | quote) "" }}
   {{- $_ := unset $dict $k }}
  {{- end }}
{{- end }}
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

{{/* Build the list of port for deployment service */}}
{{- define "opentelemetry-collector.deploymentPortsConfig" -}}
{{- $ports := deepCopy .Values.ports }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  port: {{ $port.servicePort }}
  targetPort: {{ $key }}
  protocol: {{ $port.protocol }}
{{- end }}
{{- end }}
{{- end }}
