{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "opentelemetry-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-operator.labels" -}}
helm.sh/chart: {{ include "opentelemetry-operator.chart" . }}
{{ include "opentelemetry-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opentelemetry-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opentelemetry-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
