{{/*
Component Depends Config
*/}}
{{- define "otel-demo.pod.dependsConfig" -}}
cart-service:
  - redis
checkout-service:
  - cart-service
  - currency-service
  - email-service
  - payment-service
  - product-catalog-service
  - shipping-service
frontend:
  - ad-service
  - cart-service
  - checkout-service
  - currency-service
  - product-catalog-service
  - recommendation-service
  - shipping-service
loadgenerator:
  - frontend
recommendation-service:
  - product-catalog-service
{{- end}}


{{/*
Get Services Port Mapping
*/}}
{{- define "otel-demo.pod.serviceMapping" -}}
{{ $servicePortMap := default dict }}
{{- range $name, $config := .Values.components }}
    {{- if $config.servicePort }}
    {{ $name | kebabcase }}: {{ $config.servicePort }}
    {{- else if $config.ports }}
    {{ $name | kebabcase}}: {{ (get (index $config.ports 0 ) "value") }}
    {{- end }}
{{- end }}
{{- end }}

{{/*
Get Pod Env 
*/}}
{{- define "otel-demo.pod.env" -}}
{{- $prefix := include "otel-demo.name" $ }}

{{- if .env }}
{{- toYaml .env }}
{{- end }}

{{- if .observability.otelcol.enabled }} 
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: http://{{ include "otel-demo.name" . }}-otelcol:4317
- name: OTEL_RESOURCE_ATTRIBUTES
  value: service.name={{ .name | kebabcase }}
{{- end }}

{{- if .servicePort}}
- name: {{ printf "%s_PORT" .name | snakecase | upper }}
  value: {{.servicePort | quote}} 
{{- end }}

# {{ $.depends }}
# {{ .name }}
{{- if hasKey $.depends .name }}
{{- range $depend := get $.depends .name }}
- name: {{ printf "%s_ADDR" $depend | snakecase | upper }}
  value: {{ printf "%s-%s:%0.f" $prefix ($depend | kebabcase) (get $.serviceMapping $depend )}}
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
