{{- define "otel-demo.deployment" }}
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
      {{- if or .defaultValues.image.pullSecrets ((.imageOverride).pullSecrets) }}
      imagePullSecrets:
        {{- ((.imageOverride).pullSecrets) | default .defaultValues.image.pullSecrets | toYaml | nindent 8}}
      {{- end }}
      {{- with .serviceAccountName }}
      serviceAccountName: {{ .serviceAccountName}}
      {{- end }}
      {{- $schedulingRules := .schedulingRules | default dict }}
      {{- if or .defaultValues.schedulingRules.nodeSelector $schedulingRules.nodeSelector}}
      nodeSelector:
        {{- $schedulingRules.nodeSelector | default .defaultValues.schedulingRules.nodeSelector | toYaml | nindent 8 }}
      {{- end }}
      {{- if or .defaultValues.schedulingRules.affinity $schedulingRules.affinity}}
      affinity:
        {{- $schedulingRules.affinity | default .defaultValues.schedulingRules.affinity | toYaml | nindent 8 }}
      {{- end }}
      {{- if or .defaultValues.schedulingRules.tolerations $schedulingRules.tolerations}}
      tolerations:
        {{- $schedulingRules.tolerations | default .defaultValues.schedulingRules.tolerations | toYaml | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .name }}
          image: '{{ ((.imageOverride).repository) | default .defaultValues.image.repository }}:{{ ((.imageOverride).tag) | default (printf "v%s-%s" (default .Chart.AppVersion .defaultValues.image.tag) (replace "-" "" .name)) }}'
          imagePullPolicy: {{ ((.imageOverride).pullPolicy) | default .defaultValues.image.pullPolicy }}
          {{- if .command }}
          command:
            {{- .command | toYaml | nindent 10 -}}
          {{- end }}
          {{- if or .ports .servicePort}}
          ports:
            {{- include "otel-demo.pod.ports" . | nindent 10 }}
          {{- end }}
          env:
            {{- include "otel-demo.pod.env" . | nindent 10 }}
          resources:
            {{- .resources | toYaml | nindent 12 }}
	  {{- if or .defaultValues.securityContext .securityContext }}
          securityContext:
            {{- .securityContext | default .defaultValues.securityContext | toYaml | nindent 12 }}
	  {{- end}}

      {{- if .configuration }}
          volumeMounts:
          - name: config
            mountPath: /etc/config
      volumes:
        - name: config
          configMap:
            name: {{ include "otel-demo.name" . }}-{{ .name }}-config
      {{- end }}
{{- end }}

{{- define "otel-demo.service" }}
{{- if or .ports .servicePort}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "otel-demo.name" . }}-{{ .name }}
  labels:
    {{- include "otel-demo.labels" . | nindent 4 }}
spec:
  type: {{ .serviceType | default "ClusterIP" }}
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
{{- define "otel-demo.configmap" }}
{{- if .configuration}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "otel-demo.name" . }}-{{ .name }}-config
  labels:
    service: {{ include "otel-demo.name" . }}-{{ .name }}
    app: {{ include "otel-demo.name" . }}-{{ .name }}
    component: {{ include "otel-demo.name" . }}-{{ .name }}-config
data:
  {{- .configuration | toYaml | nindent 2}}
{{- end}}
{{- end}}

{{- define "otel-demo.ingress" }}
{{- $hasIngress := false}}
{{- if .ingress }}
{{- if .ingress.enabled }}
{{- $hasIngress = true }}
{{- end }}
{{- end }}
{{- if and $hasIngress (or .ports .servicePort) }}
{{- $ingresses := list .ingress }}
{{- if .ingress.additionalIngresses }}
{{-   $ingresses := concat $ingresses .ingress.additionalIngresses -}}
{{- end }}
{{- range $ingresses }}
---
apiVersion: "networking.k8s.io/v1"
kind: Ingress
metadata:
  {{- if .name }}
  name: {{include "otel-demo.name" $ }}-{{ $.name }}-{{ .name }}
  {{- else }}
  name: {{include "otel-demo.name" $ }}-{{ $.name }}
  {{- end }}
  labels:
    {{- include "otel-demo.labels" $ | nindent 4 }}
  {{- if .annotations }}
  annotations:
    {{ toYaml .annotations | nindent 4 }}
  {{- end }}
spec:
  {{- if .ingressClassName }}
  ingressClassName: {{ .ingressClassName }}
  {{- end -}}
  {{- if .tls }}
  tls:
    {{- range .tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      {{- with .secretName }}
      secretName: {{ . }}
      {{- end }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "otel-demo.name" $ }}-{{ $.name }}
                port:
                  number: {{ .port }}
          {{- end }}
    {{- end }}
{{- end}}
{{- end}}
{{- end}}
