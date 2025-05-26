{{- define "opentelemetry-collector.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "opentelemetry-collector.serviceAccountName" . }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
containers:
  - name: {{ include "opentelemetry-collector.lowercase_chartname" . }}
    command:
      {{- if .Values.isWindows }}
      - "C:\\otelcol-contrib.exe"
      {{- if .Values.configMap.create }}
      - --config=C:\\conf\relay.yaml
      {{- end }}
      {{- else }}
      - /{{ .Values.command.name }}
      {{- if .Values.configMap.create }}
      - --config=/conf/relay.yaml
      {{- end }}
      {{- range .Values.command.extraArgs }}
      - {{ . }}
      {{- end }}
      {{- end }}
    securityContext:
      {{- if and (not (.Values.securityContext)) (not (.Values.isWindows)) (or (.Values.presets.logsCollection.storeCheckpoints) (.Values.presets.hostMetrics.process.enabled)) }}
      runAsUser: 0
      runAsGroup: 0
      {{- if .Values.presets.hostMetrics.process.enabled }}
      privileged: true
      {{- end }}
      {{- else -}}
      {{- toYaml .Values.securityContext | nindent 6 }}
      {{- end }}
    {{- if .Values.image.digest }}
    image: "{{ .Values.image.repository }}@{{ .Values.image.digest }}"
    {{- else }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
    {{- end }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    {{- $ports := include "opentelemetry-collector.podPortsConfig" . }}
    {{- if $ports }}
    ports:
      {{- $ports | nindent 6}}
    {{- end }}
    env:
      - name: MY_POD_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.podIP
      {{- if .Values.targetAllocator.enabled }}
      - name: MY_POD_NAME
        valueFrom:
          fieldRef:
            fieldPath: metadata.name
      {{- end }}
      {{- if and .Values.presets.kubernetesAttributes.enabled (eq .Values.mode "daemonset") }}
      - name: K8S_NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      {{- end }}
      {{- if or .Values.presets.kubeletMetrics.enabled .Values.presets.kubernetesExtraMetrics.perNode }}
      - name: K8S_NODE_IP
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: status.hostIP
      {{- end }}
      {{- if and (.Values.useGOMEMLIMIT) ((((.Values.resources).limits).memory))  }}
      - name: GOMEMLIMIT
        value: {{ include "opentelemetry-collector.gomemlimit" .Values.resources.limits.memory | quote }}
      {{- end }}
      {{- if .Values.presets.resourceDetection.enabled }}
      {{- $otelAttrExists := false }}
      {{- $kubeNodeExists := false }}
      {{- if .Values.extraEnvs }}
      {{- range .Values.extraEnvs }}
      {{- if eq .name "OTEL_RESOURCE_ATTRIBUTES" }}
      {{- $otelAttrExists = true }}
      {{- end }}
      {{- if eq .name "KUBE_NODE_NAME" }}
      {{- $kubeNodeExists = true }}
      {{- end }}
      {{- end }}
      {{- end }}
      {{- if not $otelAttrExists }}
      - name: OTEL_RESOURCE_ATTRIBUTES
        value: "k8s.node.name=$(K8S_NODE_NAME)"
      {{- end }}
      {{- if not $kubeNodeExists }}
      - name: KUBE_NODE_NAME
        valueFrom:
          fieldRef:
            apiVersion: v1
            fieldPath: spec.nodeName
      {{- end }}
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
    livenessProbe:
      {{- if .Values.livenessProbe.initialDelaySeconds | empty | not }}
      initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
      {{- end }}
      {{- if .Values.livenessProbe.periodSeconds | empty | not }}
      periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
      {{- end }}
      {{- if .Values.livenessProbe.timeoutSeconds | empty | not }}
      timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
      {{- end }}
      {{- if .Values.livenessProbe.failureThreshold | empty | not }}
      failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
      {{- end }}
      {{- if .Values.livenessProbe.terminationGracePeriodSeconds | empty | not }}
      terminationGracePeriodSeconds: {{ .Values.livenessProbe.terminationGracePeriodSeconds }}
      {{- end }}
      httpGet:
        path: {{ .Values.livenessProbe.httpGet.path }}
        port: {{ .Values.livenessProbe.httpGet.port }}
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
    readinessProbe:
      {{- if .Values.readinessProbe.initialDelaySeconds | empty | not }}
      initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
      {{- end }}
      {{- if .Values.readinessProbe.periodSeconds | empty | not }}
      periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
      {{- end }}
      {{- if .Values.readinessProbe.timeoutSeconds | empty | not }}
      timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
      {{- end }}
      {{- if .Values.readinessProbe.successThreshold | empty | not }}
      successThreshold: {{ .Values.readinessProbe.successThreshold }}
      {{- end }}
      {{- if .Values.readinessProbe.failureThreshold | empty | not }}
      failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
      {{- end }}
      httpGet:
        path: {{ .Values.readinessProbe.httpGet.path }}
        port: {{ .Values.readinessProbe.httpGet.port }}
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      {{- if .Values.configMap.create }}
      - mountPath: {{ .Values.isWindows | ternary "C:\\conf" "/conf" }}
        name: {{ include "opentelemetry-collector.lowercase_chartname" . }}-configmap
      {{- end }}
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
      {{- if .Values.presets.logsCollection.enabled }}
      {{- if .Values.isWindows }}
      - name: varlogpods
        mountPath: C:\var\log\pods
        readOnly: true
      {{- else }}
      - name: varlogpods
        mountPath: /var/log/pods
        readOnly: true
      {{- if ne .Values.distribution "gke/autopilot" }}
      - name: varlibdockercontainers
        mountPath: /var/lib/docker/containers
        readOnly: true
      {{- end }}
      {{- end }}
      {{- if .Values.presets.logsCollection.storeCheckpoints}}
      - name: varlibotelcol
        mountPath: /var/lib/otelcol
      {{- end }}
      {{- end }}
      {{- if .Values.presets.hostMetrics.enabled }}
      {{- if .Values.isWindows }}
      - mountPath: "C:\\hostfs"
        name: hostfs
        readOnly: true
      {{- else }}
      - name: hostfs
        mountPath: /hostfs
        readOnly: true
        mountPropagation: HostToContainer
      {{- end }}
      {{- end }}
      {{- if .Values.presets.resourceDetection.enabled }}
      {{- if not .Values.isWindows }}
      {{- $machineIdMountExists := false }}
      {{- $dbusMachineIdMountExists := false }}
      {{- if .Values.extraVolumeMounts }}
      {{- range .Values.extraVolumeMounts }}
      {{- if eq .mountPath "/etc/machine-id" }}
      {{- $machineIdMountExists = true }}
      {{- end }}
      {{- if eq .mountPath "/var/lib/dbus/machine-id" }}
      {{- $dbusMachineIdMountExists = true }}
      {{- end }}
      {{- end }}
      {{- end }}
      {{- if not $machineIdMountExists }}
      - mountPath: /etc/machine-id
        mountPropagation: HostToContainer
        name: etcmachineid
        readOnly: true
      {{- end }}
      {{- if not $dbusMachineIdMountExists }}
      - mountPath: /var/lib/dbus/machine-id
        mountPropagation: HostToContainer
        name: varlibdbusmachineid
        readOnly: true
      {{- end }}
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
priorityClassName: {{ include "opentelemetry-collector.priorityClassName" . | quote }}
{{- end }}
volumes:
  {{- if .Values.configMap.create }}
  - name: {{ include "opentelemetry-collector.lowercase_chartname" . }}-configmap
    configMap:
      name: {{ include "opentelemetry-collector.fullname" . }}{{ .configmapSuffix }}
      items:
        - key: relay
          path: relay.yaml
  {{- end }}
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
  {{- if .Values.presets.logsCollection.enabled }}
  {{- if .Values.isWindows }}
  - name: varlogpods
    hostPath:
      path: C:\var\log\pods
  - name: programdata
    hostPath:
      path: C:\ProgramData
  {{- else }}
  - name: varlogpods
    hostPath:
      path: /var/log/pods
  {{- if ne .Values.distribution "gke/autopilot" }}
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
  {{- end }}
  {{- end }}
  {{- if .Values.presets.logsCollection.storeCheckpoints}}
  - name: varlibotelcol
    hostPath:
      path: /var/lib/otelcol
      type: DirectoryOrCreate
  {{- end }}
  {{- end }}
  {{- if .Values.presets.hostMetrics.enabled }}
  {{- if .Values.isWindows }}
  - name: hostfs
    hostPath:
      path: "C:\\"
  {{- else }}
  - name: hostfs
    hostPath:
      path: /
  {{- end }}
  {{- end }}
  {{- if .Values.presets.resourceDetection.enabled }}
  {{- if not .Values.isWindows }}
  {{- $machineIdVolumeExists := false }}
  {{- $dbusMachineIdVolumeExists := false }}
  {{- if .Values.extraVolumes }}
  {{- range .Values.extraVolumes }}
  {{- if and (eq .name "etcmachineid") (eq .hostPath.path "/etc/machine-id") }}
  {{- $machineIdVolumeExists = true }}
  {{- end }}
  {{- if and (eq .name "varlibdbusmachineid") (eq .hostPath.path "/var/lib/dbus/machine-id") }}
  {{- $dbusMachineIdVolumeExists = true }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if not $machineIdVolumeExists }}
  - name: etcmachineid
    hostPath:
      path: /etc/machine-id
  {{- end }}
  {{- if not $dbusMachineIdVolumeExists }}
  - name: varlibdbusmachineid
    hostPath:
      path: /var/lib/dbus/machine-id
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if .Values.extraVolumes }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
  {{- end }}
nodeSelector:
{{- if .Values.nodeSelector }}
{{ toYaml .Values.nodeSelector | nindent 2 }}
{{- else }}
  kubernetes.io/os: {{ .Values.isWindows | ternary "windows" "linux" }}
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
