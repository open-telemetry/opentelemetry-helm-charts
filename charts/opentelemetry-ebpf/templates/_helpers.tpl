{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-ebpf.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "opentelemetry-ebpf.lowercase_chartname" -}}
{{- default .Chart.Name | lower }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-ebpf.fullname" -}}
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
{{- define "opentelemetry-ebpf.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-ebpf.labels" -}}
helm.sh/chart: {{ include "opentelemetry-ebpf.chart" . }}
{{ include "opentelemetry-ebpf.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opentelemetry-ebpf.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opentelemetry-ebpf.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Fully qualified app name for the cloud-collector deployment.
*/}}
{{- define "opentelemetry-collector-cloud-collector.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-cloud-collector" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-cloud-collector" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the cloud-collector
*/}}
{{- define "opentelemetry-collector-cloud-collector.serviceAccountName" -}}
{{- if .Values.cloudCollector.serviceAccount.create }}
{{- default (include "opentelemetry-collector-cloud-collector.fullname" .) .Values.cloudCollector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.cloudCollector.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fully qualified app name for the k8s-collector deployment.
*/}}
{{- define "opentelemetry-collector-k8s-collector.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-k8s-collector" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-k8s-collector" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the k8s-collector
*/}}
{{- define "opentelemetry-collector-k8s-collector.serviceAccountName" -}}
{{- if .Values.k8sCollector.serviceAccount.create }}
{{- default (include "opentelemetry-collector-k8s-collector.fullname" .) .Values.k8sCollector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.k8sCollector.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fully qualified app name for the kernel-collector daemonset.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-collector-kernel-collector.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-kernel-collector" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-kernel-collector" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for the kernel-collector
*/}}
{{- define "opentelemetry-collector-kernel-collector.serviceAccountName" -}}
{{- if .Values.kernelCollector.serviceAccount.create }}
{{- default (include "opentelemetry-collector-kernel-collector.fullname" .) .Values.kernelCollector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.kernelCollector.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fully qualified app name for the reducer deployment.
*/}}
{{- define "opentelemetry-collector-reducer.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-reducer" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-reducer" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Build the list of port for service */}}
{{- define "opentelemetry-collector-reducer.servicePortsConfig" -}}
{{- $ports := deepCopy .Values.reducer.service.ports }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  port: {{ $port.servicePort }}
  targetPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if $port.appProtocol }}
  appProtocol: {{ $port.appProtocol }}
  {{- end }}
{{- if $port.nodePort }}
  nodePort: {{ $port.nodePort }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for podDisruptionBudget.
*/}}
{{- define "podSecurityPolicy.apiVersion" -}}
  {{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
    {{- print "policy/v1" -}}
  {{- else -}}
    {{- print "policy/v1beta1" -}}
  {{- end -}}
{{- end -}}