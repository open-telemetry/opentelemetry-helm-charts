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

{{- define "otel-demo.otelcol.config" -}}
receivers:
  otlp:
    protocols:
      grpc:
      http:
exporters:
  {{- if .Values.observability.jaeger.enabled }}
  jaeger:
    endpoint: "${JAEGER_ADDR}"
    tls:
      insecure: true
  {{- end}}
  logging:

processors:
  batch:

service:
  pipelines:
    traces:
      receivers: 
        - otlp
      processors: 
        - batch
      exporters: 
        - logging
        {{- if .Values.observability.jaeger.enabled }}
        - jaeger
        {{- end}}
{{- end }}
