{{/*
Expand the name of the chart.
*/}}
{{- define "obi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "obi.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "obi.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "obi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "obi.labels" -}}
helm.sh/chart: {{ include "obi.chart" . }}
{{ include "obi.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: obi
{{- end }}

{{/*
Selector (pod) labels
*/}}
{{- define "obi.selectorLabels" -}}
app.kubernetes.io/name: {{ include "obi.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with .Values.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "obi.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "obi.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Calculate name of image ID to use for "obi".
*/}}
{{- define "obi.imageId" -}}
{{- if .Values.image.digest }}
{{- $digest := .Values.image.digest }}
{{- if not (hasPrefix "sha256:" $digest) }}
{{- $digest = printf "sha256:%s" $digest }}
{{- end }}
{{- printf "@%s" $digest }}
{{- else if .Values.image.tag }}
{{- printf ":%s" .Values.image.tag }}
{{- else }}
{{- printf ":%s" .Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
Calculate name of image ID to use for "obi-cache".
*/}}
{{- define "obi.k8sCache.imageId" -}}
{{- if .Values.k8sCache.image.digest }}
{{- $digest := .Values.k8sCache.image.digest }}
{{- if not (hasPrefix "sha256:" $digest) }}
{{- $digest = printf "sha256:%s" $digest }}
{{- end }}
{{- printf "@%s" $digest }}
{{- else if .Values.k8sCache.image.tag }}
{{- printf ":%s" .Values.k8sCache.image.tag }}
{{- else }}
{{- printf ":%s" .Chart.AppVersion }}
{{- end }}
{{- end }}

{{/*
Common kube cache labels
*/}}
{{- define "obi.cache.labels" -}}
helm.sh/chart: {{ include "obi.chart" . }}
{{ include "obi.cache.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: obi
{{- end }}

{{/*
Selector (pod) labels
*/}}
{{- define "obi.cache.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.k8sCache.service.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with .Values.k8sCache.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "obi.podAnnotations" -}}
{{- if .Values.podAnnotations }}
{{- tpl (.Values.podAnnotations | toYaml) . }}
{{- end }}
{{- end }}

{{/* Default Config v1 values retained for backwards compatibility. */}}
{{- define "obi.defaultConfig.v1" -}}
otel_traces_export:
  endpoint: "http://${HOST_IP}:4317"
otel_metrics_export:
  endpoint: "http://${HOST_IP}:4318"
attributes:
  kubernetes:
    enable: true
filter:
  network:
    k8s_dst_owner_name:
      not_match: '{kube*,*jaeger-agent*,*prometheus*,*promtail*,*grafana-agent*}'
    k8s_src_owner_name:
      not_match: '{kube*,*jaeger-agent*,*prometheus*,*promtail*,*grafana-agent*}'
prometheus_export:
  port: 9090
  path: /metrics
{{- end }}

{{/* Helm-compatible OBI Config v2 defaults. */}}
{{- define "obi.defaultConfig.v2" -}}
file_format: "1.0"
log_level: info
resource: {}
propagator: {}
tracer_provider:
  processors:
    - batch:
        max_queue_size: 16384
        max_export_batch_size: 4096
        schedule_delay: 15000
        exporter:
          otlp_grpc:
            endpoint: "http://${HOST_IP}:4317"
            tls:
              insecure: true
meter_provider:
  readers:
    - periodic:
        interval: 60000
        exporter:
          otlp_http:
            endpoint: "http://${HOST_IP}:4318"
            encoding: protobuf
            default_histogram_aggregation: explicit_bucket_histogram
    - pull:
        exporter:
          prometheus/development:
            port: 9090
extensions:
  obi:
    version: "2.0"
    capture:
      instrumentation:
        dns:
          enabled:
            traces: false
            metrics: true
      network:
        capture:
          enabled: false
          filters:
            traces:
              k8s_dst_owner_name:
                not_match: '{kube*,*jaeger-agent*,*prometheus*,*promtail*,*grafana-agent*}'
              k8s_src_owner_name:
                not_match: '{kube*,*jaeger-agent*,*prometheus*,*promtail*,*grafana-agent*}'
            metrics:
              k8s_dst_owner_name:
                not_match: '{kube*,*jaeger-agent*,*prometheus*,*promtail*,*grafana-agent*}'
              k8s_src_owner_name:
                not_match: '{kube*,*jaeger-agent*,*prometheus*,*promtail*,*grafana-agent*}'
    enrich:
      enrichers:
        kubernetes:
          mode: enabled
{{- end }}

{{/* Config v2 rules used by the application preset. */}}
{{- define "obi.defaultRules.v2" -}}
- action: exclude
  name: exclude-obi-and-collectors
  description: Exclude OBI and collector binaries to avoid self-instrumentation and collector recursion.
  match:
    process:
      exe_path_glob:
        - '{*/obi,obi,*otelcol,*otelcol-contrib,*otelcol-contrib[!/]*}'
- action: exclude
  name: exclude-system-namespaces
  description: Exclude common platform and system Kubernetes namespaces.
  match:
    kubernetes:
      namespace_glob:
        - kube-system
        - kube-node-lease
        - local-path-storage
        - cert-manager
        - monitoring
        - gke-connect
        - gke-gmp-system
        - gke-managed-cim
        - gke-managed-filestorecsi
        - gke-managed-metrics-server
        - gke-managed-system
        - gke-system
        - gke-managed-volumepopulator
        - gatekeeper-system
- action: exclude
  name: exclude-otlp-exporters
  description: Exclude services that already export OTLP to prevent duplicate telemetry pipelines.
  match:
    process:
      exports_otlp:
        port: 4317
        protocol: protobuf
{{- end }}

{{/* Generate chart defaults for the Config v2 application preset. */}}
{{- define "obi.applicationPresetConfig.v2" -}}
extensions:
  obi:
    capture:
      policy:
        default_action: exclude
        match_order: first_match_wins
      rules:
{{ include "obi.defaultRules.v2" . | indent 8 }}
        - action: exclude
          name: exclude-ebpf-instrument-and-otelcol
          match:
            process:
              exe_path_glob:
                - '{*ebpf-instrument*,*otelcol*}'
        - action: include
          name: include-all-kubernetes-applications
          match:
            process:
              exe_path_glob:
                - '*'
            kubernetes:
              namespace_glob:
                - '*'
{{- end }}

{{/* Remove keys explicitly set to null in user overrides. */}}
{{- define "obi.removeNulls" -}}
{{- $target := index . 0 -}}
{{- $overrides := index . 1 -}}
{{- range $key, $value := $overrides -}}
  {{- if eq $value nil -}}
    {{- $_ := unset $target $key -}}
  {{- else if and (kindIs "map" $value) (kindIs "map" (get $target $key)) -}}
    {{- $_ := include "obi.removeNulls" (list (get $target $key) $value) -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
Generate the effective config based on its schema, preset, and user overrides.
An empty config defaults to v2. Non-empty config without the v2 marker is v1.
*/}}
{{- define "obi.configData" -}}
{{- $userConfig := deepCopy (.Values.config.data | default dict) -}}
{{- $userExtensions := get $userConfig "extensions" | default dict -}}
{{- $userObi := get $userExtensions "obi" | default dict -}}
{{- $obiVersion := get $userObi "version" | default "" | toString -}}
{{- if and (hasKey $userConfig "file_format") (eq $obiVersion "") -}}
{{- fail "config.data.file_format requires config.data.extensions.obi.version: \"2.0\"" -}}
{{- end -}}
{{- if and (hasKey $userConfig "file_format") (ne (get $userConfig "file_format" | toString) "1.0") -}}
{{- fail (printf "unsupported config.data.file_format %q; supported version is \"1.0\"" (get $userConfig "file_format" | toString)) -}}
{{- end -}}
{{- if and (ne $obiVersion "") (ne $obiVersion "2.0") -}}
{{- fail (printf "unsupported config.data.extensions.obi.version %q; supported version is \"2.0\"" $obiVersion) -}}
{{- end -}}
{{- $isV2 := or (empty $userConfig) (eq $obiVersion "2.0") -}}
{{- $config := dict -}}
{{- if $isV2 -}}
  {{- $config = include "obi.defaultConfig.v2" . | fromYaml -}}
  {{- $userCapture := dig "capture" (dict) $userObi -}}
  {{- if eq .Values.preset "application" -}}
    {{- $presetConfig := include "obi.applicationPresetConfig.v2" . | fromYaml -}}
    {{- if hasKey $userCapture "rules" -}}
      {{- $presetCapture := dig "extensions" "obi" "capture" (dict) $presetConfig -}}
      {{- $_ := unset $presetCapture "rules" -}}
    {{- end -}}
    {{- $config = mergeOverwrite $config $presetConfig -}}
  {{- else if eq .Values.preset "network" -}}
    {{- $userNetwork := dig "network" (dict) $userCapture -}}
    {{- $userNetworkCapture := dig "capture" (dict) $userNetwork -}}
    {{- if not (hasKey $userNetworkCapture "enabled") -}}
      {{- $networkPreset := dict "extensions" (dict "obi" (dict "capture" (dict "network" (dict "capture" (dict "enabled" true))))) -}}
      {{- $config = mergeOverwrite $config $networkPreset -}}
    {{- end -}}
  {{- end -}}
{{- else -}}
  {{- $config = include "obi.defaultConfig.v1" . | fromYaml -}}
  {{- if and (eq .Values.preset "network") (not (get $userConfig "network")) -}}
    {{- $_ := set $config "network" (dict "enable" true) -}}
  {{- end -}}
  {{- if and (eq .Values.preset "application") (not (get $userConfig "discovery")) -}}
    {{- $discovery := dict "instrument" (list (dict "k8s_namespace" "*")) "exclude_instrument" (list (dict "exe_path" "{*ebpf-instrument*,*otelcol*}")) -}}
    {{- $_ := set $config "discovery" $discovery -}}
  {{- end -}}
{{- end -}}
{{- $config = mergeOverwrite $config $userConfig -}}
{{- $_ := include "obi.removeNulls" (list $config $userConfig) -}}
{{- tpl (toYaml $config) . -}}
{{- end }}

{{/* Values derived from the effective v1 or v2 config for Kubernetes resources. */}}
{{- define "obi.configMeta" -}}
{{- if not (and .Values.config.create (eq .Values.config.name "")) -}}
{{- toYaml (dict "isV2" false "networkEnabled" (eq .Values.preset "network") "prometheusPort" 9090 "prometheusPath" "/metrics" "internalMetricsPort" 0 "internalMetricsPath" "" "profilePort" 0) -}}
{{- else -}}
{{- $config := include "obi.configData" . | fromYaml -}}
{{- $extensions := get $config "extensions" | default dict -}}
{{- $obi := get $extensions "obi" | default dict -}}
{{- $isV2 := eq (get $obi "version" | default "" | toString) "2.0" -}}
{{- $prometheusPort := 0 -}}
{{- $prometheusPath := "" -}}
{{- $internalMetricsPort := 0 -}}
{{- $internalMetricsPath := "" -}}
{{- $profilePort := 0 -}}
{{- $networkEnabled := false -}}
{{- if $isV2 -}}
  {{- $meterProvider := get $config "meter_provider" | default dict -}}
  {{- range (get $meterProvider "readers" | default list) -}}
    {{- $pull := get . "pull" | default dict -}}
    {{- $exporter := get $pull "exporter" | default dict -}}
    {{- $prometheus := get $exporter "prometheus/development" | default dict -}}
    {{- if hasKey $prometheus "port" -}}
      {{- $prometheusPort = get $prometheus "port" -}}
      {{- $prometheusPath = "/metrics" -}}
    {{- end -}}
  {{- end -}}
  {{- $capture := get $obi "capture" | default dict -}}
  {{- $network := get $capture "network" | default dict -}}
  {{- $networkCapture := get $network "capture" | default dict -}}
  {{- $networkStats := get $network "stats" | default dict -}}
  {{- $networkEnabled = or (get $networkCapture "enabled" | default false) (get $networkStats "enabled" | default false) -}}
  {{- $daemon := get $obi "daemon" | default dict -}}
  {{- $internalMetrics := get $daemon "internal_metrics" | default dict -}}
  {{- $internalPrometheus := get $internalMetrics "prometheus" | default dict -}}
  {{- $internalMetricsPort = get $internalPrometheus "port" | default 0 -}}
  {{- $internalMetricsPath = get $internalPrometheus "path" | default "/internal/metrics" -}}
  {{- $profiling := get $daemon "profiling" | default dict -}}
  {{- $profilePort = get $profiling "port" | default 0 -}}
{{- else -}}
  {{- $prometheus := get $config "prometheus_export" | default dict -}}
  {{- $prometheusPort = get $prometheus "port" | default 0 -}}
  {{- $prometheusPath = get $prometheus "path" | default "/metrics" -}}
  {{- $network := get $config "network" | default dict -}}
  {{- $networkEnabled = get $network "enable" | default false -}}
  {{- $internalMetrics := get $config "internal_metrics" | default dict -}}
  {{- $internalPrometheus := get $internalMetrics "prometheus" | default dict -}}
  {{- $internalMetricsPort = get $internalPrometheus "port" | default 0 -}}
  {{- $internalMetricsPath = get $internalPrometheus "path" | default "/metrics" -}}
  {{- $profilePort = get $config "profile_port" | default 0 -}}
{{- end -}}
{{- toYaml (dict "isV2" $isV2 "networkEnabled" $networkEnabled "prometheusPort" $prometheusPort "prometheusPath" $prometheusPath "internalMetricsPort" $internalMetricsPort "internalMetricsPath" $internalMetricsPath "profilePort" $profilePort) -}}
{{- end -}}
{{- end }}
