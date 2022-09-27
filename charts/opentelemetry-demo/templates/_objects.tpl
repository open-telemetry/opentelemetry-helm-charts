{{- define "otel.demo.deployment" }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "otel-demo.name" . }}-{{ .name }}
  labels:
    {{- include "otel-demo.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "otel-demo.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "otel-demo.selectorLabels" . | nindent 8 }}
      {{- if .podAnnotations }}
      annotations:
        {{- toYaml .podAnnotations | nindent 8 }}
      {{- end }}
    spec:
      {{- if .imageConfig.pullSecrets }}
      imagePullSecrets:
        {{- toYaml .imageConfig.pullSecrets | nindent 8}}
      {{- end }}
      {{- with .serviceAccountName }}
      serviceAccountName: {{ .serviceAccountName}}
      {{- end }}
      containers:
        - name: {{ .name }}
          image: {{ .image | default (printf "%s:v%s-%s" .imageConfig.repository .Chart.AppVersion (.name | replace "-" "" | lower)) }}
          {{- if or .ports .servicePort}}
          ports:
            {{- include "otel-demo.pod.ports" . | nindent 10 }}
          {{- end }}
          env:
            {{- include "otel-demo.pod.env" . | nindent 10 }}
{{- end }}
{{- define "otel.demo.service" }}
{{- if or .ports .servicePort}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "otel-demo.name" . }}-{{ .name }}
  labels:
    {{- include "otel-demo.labels" . | nindent 4 }}
spec:
  ports:
    {{- if .ports }}
    {{- range $port := .ports }}
    - port: {{ $port.value }}
      name: {{ $port.name}}
      targetPort: {{ $port.value }}
    {{- end }}
    {{- end }}

    {{- if .servicePort }}
    - port: {{.servicePort}}
      name: service
      targetPort: {{ .servicePort }}
    {{- end }}
  selector:
    {{- include "otel-demo.selectorLabels" . | nindent 4 }}
{{- end}}
{{- end}}

{{- define "opentelemetry-collector.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}

{{- define "otel-demo.otelcol.config" -}}
{{- $config := deepCopy .Values.observability.otelcol.config }}
{{- if .Values.observability.jaeger.enabled }}
{{- $config = (include "opentelemetry-demo.applyJaegerConfig" $config | fromYaml) }}
{{- end }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-demo.applyJaegerConfig" -}}
{{- $config := mustMergeOverwrite (include "opentelemetry-collector.jaegerConfig" . | fromYaml) . }}
{{- $_ := set $config.service.pipelines.traces "exporters" (append $config.service.pipelines.traces.exporters "jaeger" | uniq)  }}
{{- $config | toYaml }}
{{- end }}

{{- define "opentelemetry-collector.jaegerConfig" -}}
exporters:
  jaeger:
    endpoint: "${JAEGER_ADDR}"
    tls:
      insecure: true
{{- end }}
