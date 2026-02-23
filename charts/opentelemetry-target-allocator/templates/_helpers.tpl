{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helper.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "helper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Helper used to define a namspace.
- Returns namespace from a release
- If namespaceOverride value is filled in it will replace the namespace
*/}}
{{- define "helper.namespace" -}}
  {{- default .Release.Namespace | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector Labels
*/}}
{{- define "helper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels shared by all Kubernetes objects in this chart.
*/}}
{{- define "helper.commonLabels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: opentelemetry-target-allocator
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{ include "helper.selectorLabels" . }}
{{- end }}

{{/*
Create the name of the target allocator service account to use
*/}}
{{- define "helper.targetAllocatorServiceAccountName" -}}
{{- default (printf "%s-ta" ( include "helper.fullname" .) | trunc 63 | trimSuffix "-") .Values.targetAllocator.serviceAccount.name -}}
{{- end -}}

{{/*
Create the name of the target allocator cluster role to use
*/}}
{{- define "helper.targetAllocatorClusterRoleName" -}}
{{- printf "%s-ta-clusterRole" ( include "helper.fullname" . ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the target allocator cluster config map to use
*/}}
{{- define "helper.targetAllocatorConfigMapName" -}}
{{- printf "%s-ta-configmap" ( include "helper.fullname" . ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the target allocator cluster role binding to use
*/}}
{{- define "helper.targetAllocatorClusterRoleBindingName" -}}
{{- printf "%s-ta-clusterRoleBinding" ( include "helper.fullname" . ) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the target allocator docker image name.
*/}}
{{- define "helper.dockerImageName" -}}
{{- printf "%s:%s" .Values.targetAllocator.image.repository (.Values.targetAllocator.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{/*
Create ConfigMap checksum annotation
*/}}
{{- define "helper.configTemplateChecksumAnnotation" -}}
checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
{{- end -}}

{{/*
Validate the mode value.
*/}}
{{- define "helper.validateMode" -}}
{{- if and (ne .Values.mode "deployment") (ne .Values.mode "statefulset") -}}
{{- fail "mode must be one of: deployment, statefulset" -}}
{{- end -}}
{{- end -}}

