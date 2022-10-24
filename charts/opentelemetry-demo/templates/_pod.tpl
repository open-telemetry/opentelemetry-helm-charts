{{/*
Get Pod Env
Note: Consider that dependent variables need to be declared before the referenced env varibale.
*/}}
{{- define "otel-demo.pod.env" -}}
{{- if .useDefault.env }}
{{- range $key, $value := .defaultValues.env }}
{{- if $value }}
- name: "{{ tpl $key $ }}"
{{ tpl (toYaml $value) $ | indent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- if .env }}
{{- range $key, $value := .env }}
{{- if $value }}
- name: "{{ tpl $key $ }}"
{{ tpl (toYaml $value) $ | indent 2 }}
{{- end }}
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
