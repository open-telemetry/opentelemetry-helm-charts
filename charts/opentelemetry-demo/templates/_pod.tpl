{{/*
Get Pod Env
Note: Consider that dependent variables need to be declared before the referenced env varibale.
*/}}
{{- define "otel-demo.pod.env" -}}
{{- if .useDefault.env  }}
{{ toYaml .defaultValues.env }}
{{- end }}
{{- if .env }}
{{ tpl (toYaml .env) . }}
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
