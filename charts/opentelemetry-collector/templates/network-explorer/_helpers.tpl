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
{{- if .Values.networkExplorer.kernelCollector.serviceAccount.create }}
{{- default (include "opentelemetry-collector-kernel-collector.fullname" .) .Values.networkExplorer.kernelCollector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.networkExplorer.kernelCollector.serviceAccount.name }}
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
{{- if .Values.networkExplorer.k8sCollector.serviceAccount.create }}
{{- default (include "opentelemetry-collector-k8s-collector.fullname" .) .Values.networkExplorer.k8sCollector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.networkExplorer.k8sCollector.serviceAccount.name }}
{{- end }}
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
{{- if .Values.networkExplorer.cloudCollector.serviceAccount.create }}
{{- default (include "opentelemetry-collector-cloud-collector.fullname" .) .Values.networkExplorer.cloudCollector.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.networkExplorer.cloudCollector.serviceAccount.name }}
{{- end }}
{{- end }}