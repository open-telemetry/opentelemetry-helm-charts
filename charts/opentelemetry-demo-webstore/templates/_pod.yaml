{{/*
Get  Pod Env 
*/}}
{{- define "otel-demo.pod.env" -}}

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

{{- if .depends_on }}
{{- $prefix := include "otel-demo.name" $ }}
{{- range $depend := .depends_on }}
- name: {{ printf "%s_ADDR " $depend | upper | replace "-" "_" }}
  value: {{ printf "%s-%s:%0.f" $prefix $depend (get $.servicePortMap $depend )}}
{{- end }}
{{- end }}

{{- end }}

{{/*
Get Pod ports 
*/}}
{{- define "otel-demo.pod.ports" -}}
{{- if .ports }}
{{- range $port := .ports }}
- containerPort: {{ $port.value }}
  name: {{ $port.name}}
{{- end }}
{{- end }}

{{- if .servicePort }}
- containerPort: {{.servicePort}}
  name: service
{{- end }}
{{- end }}
