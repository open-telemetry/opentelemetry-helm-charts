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
Note: Consider that dependent variables need to be declared before the referenced env varibale.
*/}}
{{- define "otel-demo.pod.env" -}}
{{- $prefix := include "otel-demo.name" $ }}
{{/*
Exclude email service and treat differently because the addr. for the email service needs to contain the http:// protocol prefix.
*/}}
{{- if .depends }}
{{- range $depend := (without .depends "email-service") }}
- name: {{ printf "%s_ADDR" $depend | snakecase | upper }}
  value: {{ printf "%s-%s:%0.f" $prefix ($depend | kebabcase) (get $.serviceMapping $depend )}}
{{- end }}

{{- if has "email-service" .depends }}
- name: {{ printf "EMAIL_SERVICE_ADDR" }}
  value: {{ printf "http://%s-email-service:%0.f" $prefix (get $.serviceMapping "email-service" )}}
{{- end }}
{{- end }}

{{- if eq .name "featureflag-service" }}
{{- $hasDatabaseUrl := false }}
{{- range .env }}
{{- if eq .name "DATABASE_URL" }}
{{- $hasDatabaseUrl = true }}
{{- end}}
{{- end }}
{{- if not $hasDatabaseUrl }}
{{- $_ := set . "env" (append .env (dict "name" "DATABASE_URL" "value" (printf "ecto://ffs:ffs@%s-ffs-postgres:5432/ffs" $prefix))) }}
{{- end}}
{{- end }}

{{- if .useDefault.env  }}
{{ toYaml .defaultValues.env }}
{{- end }}

{{- if .env }}
{{ toYaml .env }}
{{- end }}

{{- if .observability.otelcol.enabled }}
{{- if eq .name "quote-service" }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: {{ include "otel-demo.name" . }}-otelcol:4317
{{- else }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: http://{{ include "otel-demo.name" . }}-otelcol:4317
{{- end }}
{{- if eq .name "shipping-service" }}
- name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
  value: http://{{ include "otel-demo.name" . }}-otelcol:4317
{{- end }}
{{- if eq .name "email-service" }}
- name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
  value: http://{{ include "otel-demo.name" . }}-otelcol:4318/v1/traces
{{- end }}
{{- end }}

{{- if .servicePort}}
- name: {{ printf "%s_PORT" .name | snakecase | upper }}
  value: {{.servicePort | quote}}
{{- end }}

{{- if eq .name "product-catalog-service" }}
- name: FEATURE_FLAG_GRPC_SERVICE_ADDR
  value: {{ (printf "%s-featureflag-service:50053" $prefix ) }}
{{- end }}

{{- if eq .name "shipping-service" }}
- name: QUOTE_SERVICE_ADDR
  value: {{ (printf "http://%s-quote-service:8080" $prefix ) }}
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
