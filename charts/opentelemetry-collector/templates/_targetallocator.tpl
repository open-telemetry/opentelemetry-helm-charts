{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-targetallocator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 47 | trimSuffix "-" }}-targetallocator
{{- end }}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-targetallocator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-targetallocator" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Create the name of the service account to use
*/}}
{{- define "opentelemetry-targetallocator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opentelemetry-targetallocator.fullname" .) .Values.targetallocator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.targetallocator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-targetallocator.labels" -}}
helm.sh/chart: {{ include "opentelemetry-collector.chart" . }}
{{ include "opentelemetry-targetallocator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opentelemetry-targetallocator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opentelemetry-targetallocator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "opentelemetry-targetallocator.podAnnotations" -}}
{{- if .Values.targetallocator.podAnnotations }}
{{- .Values.targetallocator.podAnnotations | toYaml }}
{{- end }}
{{- end }}

{{- define "opentelemetry-targetallocator.podLabels" -}}
{{- if .Values.targetallocator.podLabels }}
{{- .Values.targetallocator.podLabels | toYaml }}
{{- end }}
{{- end }}

{{/* Build the list of port for targetallocator deployment service */}}
{{- define "opentelemetry-targetallocator.deploymentPortsConfig" -}}
{{- $ports := deepCopy .Values.targetallocator.ports }}
{{- range $index, $port := $ports }}
- name: {{ $port.name }}
  port: {{ $port.servicePort }}
  targetPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
{{- end }}
{{- end }}
