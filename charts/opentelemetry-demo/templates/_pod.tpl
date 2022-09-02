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

{{- if .default.enabled  }}
{{- if .env }}
{{- $defaultEnvMap := dict }}
{{- range $defaultEnvItem := $.default.env }}
{{- $defaultEnvMap = set $defaultEnvMap $defaultEnvItem.name $defaultEnvItem }}
{{- end }}
{{- $envMap := dict }}
{{- range $envItem := $.env }}
{{- $envMap := set $envMap $envItem.name $envItem }}
{{- end }}
{{- $mergedEnvMap := merge $envMap $defaultEnvMap }}
{{- $otelResourceAttributesList := get $mergedEnvMap "OTEL_RESOURCE_ATTRIBUTES" | list }}
{{ unset $mergedEnvMap "OTEL_RESOURCE_ATTRIBUTES" | values | toYaml }}
{{ $otelResourceAttributesList | toYaml }}
{{- else }}
{{ toYaml .default.env }}
{{- end }}
{{- else if .env }}
{{ toYaml .env }}
{{- end }}

{{- if .observability.otelcol.enabled }}
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: http://{{ include "otel-demo.name" . }}-otelcol:4317
{{- end }}

{{- if .servicePort}}
- name: {{ printf "%s_PORT" .name | snakecase | upper }}
  value: {{.servicePort | quote}}
{{- end }}

{{- if eq .name "product-catalog-service" }}
- name: FEATURE_FLAG_GRPC_SERVICE_ADDR
  value: {{ (printf "%s-featureflag-service:50031" $prefix ) }}
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
