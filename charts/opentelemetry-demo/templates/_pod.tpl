{{/*
Get Pod Env
Note: Consider that dependent variables need to be declared before the referenced env variable.
*/}}
{{- define "otel-demo.pod.env" -}}
{{- if .env }}
{{ include "otel-demo.envOverriden" . }}
{{- end }}
{{- if .useDefault.env  }}
{{ include "otel-demo.envOverriden" (dict "env" .defaultValues.env "envOverrides" .defaultValues.envOverrides "Template" $.Template) }}
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
