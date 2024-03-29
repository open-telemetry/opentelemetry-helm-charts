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
Create chart name and version as used by the chart label.
*/}}
{{- define "opentelemetry-collector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-kube-stack.labels" -}}
helm.sh/chart: {{ include "opentelemetry-collector.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-collector.name" -}}
{{- default .Chart.Name .collector.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-collector.fullname" -}}
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
{{- define "opentelemetry-collector.clusterRoleName" -}}
{{- default (printf "%s-collector" .Release.Name) .Values.clusterRole.name }}
{{- end }}

{{/*
Create the name of the clusterRoleBinding to use
*/}}
{{- define "opentelemetry-collector.clusterRoleBindingName" -}}
{{- default (include "opentelemetry-collector.fullname" .) .Values.clusterRole.clusterRoleBinding.name }}
{{- end }}

{{/*
Constructs the final config for the given collector

This allows a user to supply a scrape_configs_file. This file is templated and loaded as a yaml array.
If a user has already supplied a prometheus receiver config, the file's config is appended. Finally,
the config is written as YAML.
*/}}
{{- define "opentelemetry-collector.config" -}}
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
