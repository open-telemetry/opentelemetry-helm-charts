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
      {{- if or .defaultValues.image.pullSecrets .imageOverride.pullSecrets }}
      imagePullSecrets:
        {{- .imageOverride.pullSecrets | default .defaultValues.image.pullSecrets | toYaml | nindent 8}}
      {{- end }}
      {{- with .serviceAccountName }}
      serviceAccountName: {{ .serviceAccountName}}
      {{- end }}
      {{- if .schedulingRules }}
      {{- if or .defaultValues.schedulingRules.nodeSelector .schedulingRules.nodeSelector}}
      nodeSelector:
        {{- .schedulingRules.nodeSelector | default .defaultValues.schedulingRules.nodeSelector | toYaml | nindent 8 }}
      {{- end }}
      {{- if or .defaultValues.schedulingRules.affinity .schedulingRules.affinity}}
      affinity:
        {{ toYaml .schedulingRules.affinity | default .defaultValues.schedulingRules.affinity | toYaml | nindent 8 }}
      {{- end }}
      {{- if or .defaultValues.schedulingRules.tolerations .schedulingRules.tolerations}}
      tolerations:
        {{ toYaml .schedulingRules.tolerations | default .defaultValues.schedulingRules.tolerations | toYaml | nindent 8 }}
      {{- end }}
      {{- end }}
      containers:
        - name: {{ .name }}
          image: '{{ .imageOverride.repository | default .defaultValues.image.repository }}:{{ .imageOverride.tag | default (printf "v%s-%s" (default .Chart.AppVersion .defaultValues.image.tag) (replace "-" "" .name)) }}'
          imagePullPolicy: {{ .imageOverride.pullPolicy | default .defaultValues.image.pullPolicy }}
          {{- if or .ports .servicePort}}
          ports:
            {{- include "otel-demo.pod.ports" . | nindent 10 }}
          {{- end }}
          env:
            {{- include "otel-demo.pod.env" . | nindent 10 }}
          resources:
            {{- .resources | toYaml | nindent 12 }}
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
  type: {{.serviceType}}
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
