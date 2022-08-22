{{- define "opentelemetry-targetallocator.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "opentelemetry-targetallocator.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
containers:
  - name: {{ .Chart.Name }}
    securityContext:
      {{- toYaml .Values.targetallocator.securityContext | nindent 6 }}
    image: "{{ .Values.targetallocator.image.repository }}:{{ .Values.targetallocator.image.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.targetallocator.image.pullPolicy }}
    ports:
      {{- range $index, $port := .Values.targetallocator.ports }}
      - name: {{ $port.name }}
        containerPort: {{ $port.containerPort }}
        protocol: {{ $port.protocol }}
        {{- if and $.isAgent $port.hostPort }}
        hostPort: {{ $port.hostPort }}
        {{- end }}
      {{- end }}
    env:
      - name: MY_POD_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.podIP
      {{- with .Values.targetallocator.extraEnvs }}
      {{- . | toYaml | nindent 6 }}
      {{- end }}
    resources:
      {{- toYaml .Values.targetallocator.resources | nindent 6 }}
    volumeMounts:
      {{- if .Values.configMap.create }}
      - mountPath: /conf
        name: {{ .Chart.Name }}-ta-configmap
      {{- end }}
      {{- range .Values.targetallocator.extraConfigMapMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
      {{- end }}
      {{- range .Values.targetallocator.extraHostPathMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .mountPropagation }}
        mountPropagation: {{ .mountPropagation }}
        {{- end }}
      {{- end }}
      {{- range .Values.targetallocator.secretMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
      {{- end }}
      {{- if .Values.targetallocator.extraVolumeMounts }}
      {{- toYaml .Values.targetallocator.extraVolumeMounts | nindent 6 }}
      {{- end }}
volumes:
  {{- if .Values.configMap.create }}
  - name: {{ .Chart.Name }}-configmap
    configMap:
      name: {{ include "opentelemetry-targetallocator.fullname" . }}{{ .configmapSuffix }}
      items:
        - key: targetallocator.yaml
          path: targetallocator.yaml
  {{- end }}
  {{- range .Values.targetallocator.extraConfigMapMounts }}
  - name: {{ .name }}
    configMap:
      name: {{ .configMap }}
  {{- end }}
  {{- range .Values.targetallocator.extraHostPathMounts }}
  - name: {{ .name }}
    hostPath:
      path: {{ .hostPath }}
  {{- end }}
  {{- range .Values.targetallocator.secretMounts }}
  - name: {{ .name }}
    secret:
      secretName: {{ .secretName }}
  {{- end }}
  {{- if .Values.targetallocator.extraVolumes }}
  {{- toYaml .Values.targetallocator.extraVolumes | nindent 2 }}
  {{- end }}
{{- with .Values.targetallocator.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.targetallocator.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.targetallocator.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
