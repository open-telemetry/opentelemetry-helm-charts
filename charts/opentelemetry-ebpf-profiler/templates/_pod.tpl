{{- define "opentelemetry-ebpf-profiler.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "opentelemetry-ebpf-profiler.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
containers:
  - name: {{ include "opentelemetry-ebpf-profiler.lowercase_chartname" . }}
    command:
      - /{{ .Values.command.name }}
      {{- range .Values.command.extraArgs }}
      - {{ . }}
      {{- end }}
    securityContext:
      {{- if not .Values.securityContext }}
      runAsUser: 0
      runAsGroup: 0
      privileged: true
      {{- else -}}
      {{- toYaml .Values.securityContext | nindent 6 }}
      {{- end }}
    {{- if .Values.image.digest }}
    image: "{{ .Values.image.repository }}@{{ .Values.image.digest }}"
    {{- else }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    {{- end }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    {{- $ports := include "opentelemetry-ebpf-profiler.podPortsConfig" . }}
    {{- if $ports }}
    ports:
      {{- $ports | nindent 6}}
    {{- end }}
    env:
    - name: NAMESPACE
      value: {{ include "opentelemetry-ebpf-profiler.namespace" . }}
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: spec.nodeName
    - name: HOST_IP
      valueFrom:
        fieldRef:
          apiVersion: v1
          fieldPath: status.hostIP
    - name: CORALOGIX_CONFIG
      value: config/ebpf-agent.toml
    - name: OTEL_PROFILING_AGENT_COLLECTION_AGENT
      value: "http://$(HOST_IP):4318"
      {{- if and (.Values.useGOMEMLIMIT) ((((.Values.resources).limits).memory))  }}
      - name: GOMEMLIMIT
        value: {{ include "opentelemetry-ebpf-profiler.gomemlimit" .Values.resources.limits.memory | quote }}
      {{- end }}
      {{- with .Values.extraEnvs }}
      {{- . | toYaml | nindent 6 }}
      {{- end }}
    {{- with .Values.extraEnvsFrom }}
    envFrom:
    {{- . | toYaml | nindent 6 }}
    {{- end }}
    {{- if .Values.lifecycleHooks }}
    lifecycle:
      {{- toYaml .Values.lifecycleHooks | nindent 6 }}
    {{- end }}
    {{- if .Values.startupProbe }}
    startupProbe:
      {{- if .Values.startupProbe.initialDelaySeconds | empty | not }}
      initialDelaySeconds: {{ .Values.startupProbe.initialDelaySeconds }}
      {{- end }}
      {{- if .Values.startupProbe.periodSeconds | empty | not }}
      periodSeconds: {{ .Values.startupProbe.periodSeconds }}
      {{- end }}
      {{- if .Values.startupProbe.timeoutSeconds | empty | not }}
      timeoutSeconds: {{ .Values.startupProbe.timeoutSeconds }}
      {{- end }}
      {{- if .Values.startupProbe.failureThreshold | empty | not }}
      failureThreshold: {{ .Values.startupProbe.failureThreshold }}
      {{- end }}
      {{- if .Values.startupProbe.terminationGracePeriodSeconds | empty | not }}
      terminationGracePeriodSeconds: {{ .Values.startupProbe.terminationGracePeriodSeconds }}
      {{- end }}
      {{- if .Values.startupProbe.httpGet }}
      httpGet:
        {{- if .Values.startupProbe.httpGet.path | empty | not }}
        path: {{ .Values.startupProbe.httpGet.path }}
        {{- end }}
        {{- if .Values.startupProbe.httpGet.port | empty | not }}
        port: {{ .Values.startupProbe.httpGet.port }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      - name: lsb-release
        mountPath: /etc/lsb-release.host
        readOnly: false
      - name: os-release
        mountPath: /etc/os-release.host
        readOnly: false
      - name: modules-dir
        mountPath: /lib/modules
        readOnly: false
      - name: modules-host
        mountPath: /lib/modules.host
        readOnly: false
      - name: linux-headers-generated
        mountPath: /usr/src/
        readOnly: false
      - name: boot-host
        mountPath: /boot.host
        readOnly: false
      - name: debug
        mountPath: /sys/kernel/debug
        readOnly: false
      {{- range .Values.extraConfigMapMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
      {{- end }}
      {{- range .Values.extraHostPathMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .mountPropagation }}
        mountPropagation: {{ .mountPropagation }}
        {{- end }}
      {{- end }}
      {{- range .Values.secretMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        readOnly: {{ .readOnly }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
      {{- end }}
      {{- if .Values.extraVolumeMounts }}
      {{- toYaml .Values.extraVolumeMounts | nindent 6 }}
      {{- end }}
{{- with .Values.extraContainers }}
{{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.initContainers }}
initContainers:
  {{- tpl (toYaml .Values.initContainers) . | nindent 2 }}
{{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName | quote }}
 {{- else if and (.Values.priorityClass) (or (.Values.priorityClass.create) (.Values.priorityClass.name)) }}
priorityClassName: {{ include "opentelemetry-ebpf-profiler.priorityClassName" . | quote }}
{{- end }}
volumes:
  - name: lsb-release
    hostPath:
      path: /etc/lsb-release
  - name: os-release
    hostPath:
      path: /etc/os-release
  - name: modules-dir
    hostPath:
      path: /var/cache/linux-headers/modules_dir
  - name: linux-headers-generated
    hostPath:
      path: /var/cache/linux-headers/generated
  - name: boot-host
    hostPath:
      path: /
  - name: modules-host
    hostPath:
      path: /lib/modules
  - name: debug
    hostPath:
      path: /sys/kernel/debug
  {{- range .Values.extraConfigMapMounts }}
  - name: {{ .name }}
    configMap:
      name: {{ .configMap }}
  {{- end }}
  {{- range .Values.extraHostPathMounts }}
  - name: {{ .name }}
    hostPath:
      path: {{ .hostPath }}
  {{- end }}
  {{- range .Values.secretMounts }}
  - name: {{ .name }}
    secret:
      secretName: {{ .secretName }}
  {{- end }}
  {{- if .Values.extraVolumes }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
  {{- end }}
nodeSelector:
{{- if .Values.nodeSelector }}
{{ toYaml .Values.nodeSelector | nindent 2 }}
{{- else }}
  kubernetes.io/os: "linux"
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.topologySpreadConstraints }}
topologySpreadConstraints:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}


{{/* Build the list of port for pod */}}
{{- define "opentelemetry-ebpf-profiler.podPortsConfig" -}}
{{- $ports := deepCopy .Values.ports }}
{{- $distribution := .Values.distribution }}
{{- range $key, $port := $ports }}
{{- if $port.enabled }}
- name: {{ $key }}
  containerPort: {{ $port.containerPort }}
  protocol: {{ $port.protocol }}
  {{- if and $.isAgent $port.hostPort (ne $distribution "gke/autopilot") }}
  hostPort: {{ $port.hostPort }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}