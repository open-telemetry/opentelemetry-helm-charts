{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-collector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opentelemetry-collector.lowercase_chartname" -}}
{{- default .Chart.Name | lower }}
{{- end }}

{{/*
Get component name
*/}}
{{- define "opentelemetry-collector.component" -}}
{{- if eq .Values.mode "deployment" -}}
component: standalone-collector
{{- end -}}
{{- if eq .Values.mode "daemonset" -}}
component: agent-collector
{{- end -}}
{{- if eq .Values.mode "statefulset" -}}
component: statefulset-collector
{{- end -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-collector.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "opentelemetry-collector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-collector.labels" -}}
helm.sh/chart: {{ include "opentelemetry-collector.chart" . }}
{{ include "opentelemetry-collector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "opentelemetry-collector.additionalLabels" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opentelemetry-collector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opentelemetry-collector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "opentelemetry-collector.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opentelemetry-collector.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Create the name of the clusterRole to use
*/}}
{{- define "opentelemetry-collector.clusterRoleName" -}}
{{- default (include "opentelemetry-collector.fullname" .) .Values.clusterRole.name }}
{{- end }}

{{/*
Create the name of the clusterRoleBinding to use
*/}}
{{- define "opentelemetry-collector.clusterRoleBindingName" -}}
{{- default (include "opentelemetry-collector.fullname" .) .Values.clusterRole.clusterRoleBinding.name }}
{{- end }}

{{- define "opentelemetry-collector.podAnnotations" -}}
{{- if .Values.podAnnotations }}
{{- tpl (.Values.podAnnotations | toYaml) . }}
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.podLabels" -}}
{{- if .Values.podLabels }}
{{- tpl (.Values.podLabels | toYaml) . }}
{{- end }}
{{- end }}

{{- define "opentelemetry-collector.additionalLabels" -}}
{{- if .Values.additionalLabels }}
{{- tpl (.Values.additionalLabels | toYaml) . }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for podDisruptionBudget.
*/}}
{{- define "podDisruptionBudget.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
    {{- print "policy/v1" -}}
  {{- else -}}
    {{- print "policy/v1beta1" -}}
  {{- end -}}
{{- end -}}

{{/*
Compute Service creation on mode
*/}}
{{- define "opentelemetry-collector.serviceEnabled" }}
  {{- $serviceEnabled := true }}
  {{- if not (eq (toString .Values.service.enabled) "<nil>") }}
    {{- $serviceEnabled = .Values.service.enabled -}}
  {{- end }}
  {{- if and (eq .Values.mode "daemonset") (not .Values.service.enabled) }}
    {{- $serviceEnabled = false -}}
  {{- end }}

  {{- print $serviceEnabled }}
{{- end -}}


{{/*
Compute InternalTrafficPolicy on Service creation
*/}}
{{- define "opentelemetry-collector.serviceInternalTrafficPolicy" }}
  {{- if and (eq .Values.mode "daemonset") (eq .Values.service.enabled true) }}
    {{- print (.Values.service.internalTrafficPolicy | default "Local") -}}
  {{- else }}
    {{- print (.Values.service.internalTrafficPolicy | default "Cluster") -}}
  {{- end }}
{{- end -}}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "opentelemetry-collector.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Convert memory value to numeric value in MiB to be used by otel memory_limiter processor.
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
