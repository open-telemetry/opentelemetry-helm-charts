{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-kube-stack.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-kube-stack.fullname" -}}
{{- if .fullnameOverride }}
{{- .fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}


{{/*
Add the opamp labels if they're enabled
*/}}
{{- define "opentelemetry-kube-stack.collectorOpAMPLabels" -}}
{{- if and .opAMPBridge.enabled .opAMPBridge.addReportingLabel }}
opentelemetry.io/opamp-reporting: "true"
{{- end }}
{{- if and .opAMPBridge.enabled .opAMPBridge.addManagedLabel }}
opentelemetry.io/opamp-managed: "true"
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "opentelemetry-kube-stack.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Print a map of key values in a YAML block. This is useful for labels and annotations.
*/}}
{{- define "opentelemetry-kube-stack.renderkv" -}}
{{- with . }}
{{- range $key, $value := . }}
{{- printf "%s: %s" $key $value }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Render a deduped list of environment variables and 'extraEnvs'
*/}}
{{- define "opentelemetry-kube-stack.renderenvs" -}}
{{- $envMap := dict }}
{{- range $item := .extraEnvs }}
{{- $_ := set $envMap $item.name $item.value }}
{{- end }}
{{- range $item := .env }}
{{- $_ := set $envMap $item.name $item.value }}
{{- end }}
{{- range $key, $value := $envMap }}
- name: {{ $key }}
  value: {{ $value }}
{{- end }}
{{- end }}

{{/*
Create the name of the instrumentation to use
*/}}
{{- define "opentelemetry-kube-stack.instrumentation" -}}
{{- default .Release.Name .Values.instrumentation.name }}
{{- end }}

{{/*
Create the name of the bridge to create
*/}}
{{- define "opentelemetry-opamp-bridge.fullname" -}}
{{- default .Release.Name .opAMPBridge.name }}
{{- end }}

{{/*
Create the name of the clusterRole to use for the opampbridge
*/}}
{{- define "opentelemetry-opamp-bridge.clusterRoleName" -}}
{{- default (printf "%s-bridge" .Release.Name) .Values.opAMPBridge.clusterRole.name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "opentelemetry-kube-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-kube-stack.labels" -}}
helm.sh/chart: {{ include "opentelemetry-kube-stack.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-kube-stack.collectorName" -}}
{{- default .Chart.Name .collector.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-kube-stack.collectorFullname" -}}
{{- if .fullnameOverride }}
{{- .fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name (coalesce .collector.name "") }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the clusterRole to use
*/}}
{{- define "opentelemetry-kube-stack.clusterRoleName" -}}
{{- default (printf "%s-collector" .Release.Name) .Values.clusterRole.name }}
{{- end }}

{{/*
Create the name of the clusterRoleBinding to use
*/}}
{{- define "opentelemetry-kube-stack.clusterRoleBindingName" -}}
{{- default (include "opentelemetry-kube-stack.fullname" .) .Values.clusterRole.clusterRoleBinding.name }}
{{- end }}

{{/*
Constructs the final config for the given collector

This allows a user to supply a scrape_configs_file. This file is templated and loaded as a yaml array.
If a user has already supplied a prometheus receiver config, the file's config is appended. Finally,
the config is written as YAML.
*/}}
{{- define "opentelemetry-kube-stack.config" -}}
{{- if .collector.scrape_configs_file }}
{{- $loaded_file := (.Files.Get .collector.scrape_configs_file) }}
{{- $loaded_config := (fromYamlArray (tpl $loaded_file .)) }}
{{- $prom_override := (dict "receivers" (dict "prometheus" (dict "config" (dict "scrape_configs" $loaded_config)))) }}
{{- if (dig "receivers" "prometheus" "config" "scrape_configs" false .collector.config) }}
{{- $merged_prom_scrape_configs := (concat .collector.config.receivers.prometheus.config.scrape_configs $loaded_config) }}
{{- $prom_override = (dict "receivers" (dict "prometheus" (dict "config" (dict "scrape_configs" $merged_prom_scrape_configs)))) }}
{{- end }}
{{- $new_config := (mergeOverwrite .collector.config $prom_override)}}
{{- toYaml $new_config | nindent 4 }}
{{- else }}
{{- toYaml .collector.config | nindent 4 }}
{{- end }}
{{- end }}
