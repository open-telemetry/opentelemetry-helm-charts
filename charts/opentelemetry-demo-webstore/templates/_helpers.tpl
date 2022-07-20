{{/*
Expand the name of the chart.
*/}}
{{- define "otel-demo.name" -}}
{{- default .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "otel-demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "otel-demo.labels" -}}
helm.sh/chart: {{ include "otel-demo.chart" . }}
{{ include "otel-demo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "otel-demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "otel-demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .name }}
app.kubernetes.io/component: {{ .name}}
{{- end}}
{{- end }}


{{/*
Get Deployment Env 
*/}}
{{- define "otel-demo.env" -}}
{{- if .env }}
{{- toYaml .env }}
{{- end }}

{{- if .observability.otelcol.enabled }} 
- name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
  value: http://{{ include "otel-demo.name" . }}-otelcol:4317
- name: OTEL_RESOURCE_ATTRIBUTES
  value: service.name={{ .name }}
{{- end }}

{{- if .servicePort}}
- name: {{ printf "%s_PORT " .name | upper | replace "-" "_" }}
  value: {{.servicePort | quote}} 
{{- end }}

{{- if .depends }}
{{ $prefix := include "otel-demo.name" $ }}

{{- range $depend := .depends }}

{{- if eq (typeOf $depend) "map[string]interface {}" }}
{{ $serviceName := get $depend "serviceName"}}
- name: {{ get $depend "envName" }} 
  value:  {{ printf "%s-%s:%0.f" $prefix $serviceName (get $.servicePortMap $serviceName) }}
{{- end}}

{{- if eq (typeOf $depend) "string" }}
- name: {{ printf "%s_ADDR " $depend | upper | replace "-" "_" }}
  value: {{ printf "%s-%s:%0.f" $prefix $depend (get $.servicePortMap $depend )}}
{{- end }}

{{- end }}
{{- end }}

{{- end }}
