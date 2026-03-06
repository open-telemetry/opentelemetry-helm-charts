{{- define "opentelemetry-collector.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "opentelemetry-collector.serviceAccountName" . }}
automountServiceAccountToken: {{ .Values.serviceAccount.automountServiceAccountToken }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- with .Values.hostAliases }}
hostAliases:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if $.Values.shareProcessNamespace }}
shareProcessNamespace: true
{{- end }}
containers:
  - name: {{ include "opentelemetry-collector.lowercase_chartname" . }}
    {{- if .Values.command.name }}
    command:
      - /{{ .Values.command.name }}
    {{- end }}
    args:
      {{- if or .Values.configMap.create .Values.configMap.existingName }}
      - --config=/conf/relay.yaml
      {{- end }}
      {{- range .Values.command.extraArgs }}
      - {{ . }}
      {{- end }}
    securityContext:
      {{- if and (not (.Values.securityContext)) (.Values.presets.logsCollection.storeCheckpoints) }}
      runAsUser: 0
      runAsGroup: 0
      {{- else -}}
      {{- toYaml .Values.securityContext | nindent 6 }}
      {{- end }}
    {{- if .Values.image.digest }}
    image: "{{ ternary "" (print (.Values.global).imageRegistry "/") (empty (.Values.global).imageRegistry) }}{{ .Values.image.repository }}@{{ .Values.image.digest }}"
    {{- else }}
    image: "{{ ternary "" (print (.Values.global).imageRegistry "/") (empty (.Values.global).imageRegistry) }}{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
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
      {{- if or .Values.presets.kubeletMetrics.enabled (and .Values.presets.kubernetesAttributes.enabled (eq .Values.mode "daemonset")) }}
      - name: K8S_NODE_NAME
        valueFrom:
          fieldRef:
            fieldPath: spec.nodeName
      - name: K8S_NODE_IP
        valueFrom:
          fieldRef:
            fieldPath: status.hostIP
      {{- end }}
      {{- if and (.Values.useGOMEMLIMIT) ((((.Values.resources).limits).memory))  }}
      - name: GOMEMLIMIT
        value: {{ include "opentelemetry-collector.gomemlimit" .Values.resources.limits.memory | quote }}
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
      httpGet:
        path: {{ .Values.startupProbe.httpGet.path }}
        port: {{ .Values.startupProbe.httpGet.port }}
    {{- end }}
    {{- with .Values.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    volumeMounts:
      {{- if or .Values.configMap.create .Values.configMap.existingName }}
      - mountPath: /conf
        name: {{ include "opentelemetry-collector.lowercase_chartname" . }}-configmap
      {{- end }}
      {{- if or .Values.presets.logsCollection.enabled .Values.presets.annotationDiscovery.logs.enabled }}
      - name: varlogpods
        mountPath: /var/log/pods
        readOnly: true
      - name: varlibdockercontainers
        mountPath: /var/lib/docker/containers
        readOnly: true
      {{- if .Values.presets.logsCollection.storeCheckpoints}}
      - name: varlibotelcol
        mountPath: /var/lib/otelcol
      {{- end }}
      {{- end }}
      {{- if .Values.presets.hostMetrics.enabled }}
      - name: hostfs
        mountPath: /hostfs
        readOnly: true
        mountPropagation: HostToContainer
      {{- end }}
      {{- if .Values.tenx.enabled }}
      - name: tenx-sockets
        mountPath: /tmp
      {{- end }}
      {{- if .Values.extraVolumeMounts }}
      {{- tpl (toYaml .Values.extraVolumeMounts) . | nindent 6 }}
      {{- end }}
{{- if .Values.extraContainers }}
  {{- tpl (toYaml .Values.extraContainers) . | nindent 2 }}
{{- end }}
{{- if .Values.tenx.enabled }}
  - name: tenx
    image: "{{ .Values.tenx.image.repository }}:{{ .Values.tenx.image.tag }}"
    imagePullPolicy: {{ .Values.tenx.image.pullPolicy }}
    securityContext:
      runAsUser: {{ .Values.tenx.securityContext.runAsUser | default 10001 }}
      runAsGroup: {{ .Values.tenx.securityContext.runAsGroup | default 10001 }}
    args:
      - "run"
      - "@run/input/forwarder/otel-collector/{{ .Values.tenx.kind }}"
      - "@apps/edge/{{ if eq .Values.tenx.kind "report" }}reporter{{ else if eq .Values.tenx.kind "regulate" }}regulator{{ else }}optimizer{{ end }}"
      - "otelCollectorInputPath"
      - "{{ .Values.tenx.sockets.input }}"
      {{- if ne .Values.tenx.kind "report" }}
      - "otelCollectorOutputForwardAddress"
      - "{{ .Values.tenx.sockets.output }}"
      {{- end }}
    env:
      - name: TENX_API_KEY
        value: {{ .Values.tenx.apiKey | quote }}
      {{- if .Values.tenx.runtimeName }}
      - name: TENX_RUNTIME_NAME
        value: {{ .Values.tenx.runtimeName | quote }}
      {{- end }}
      {{- if or .Values.tenx.github.config.enabled .Values.tenx.github.symbols.enabled }}
      - name: TENX_CONFIG
        value: "/etc/tenx/git/config"
      {{- end }}
      {{- if .Values.tenx.github.symbols.enabled }}
      - name: TENX_SYMBOLS_PATH
        value: "/etc/tenx/git/symbols"
      {{- end }}
    resources:
      {{- toYaml .Values.tenx.resources | nindent 6 }}
    livenessProbe:
      exec:
        command: ["pgrep", "-f", "tenx run"]
      initialDelaySeconds: 30
      periodSeconds: 10
      failureThreshold: 3
    volumeMounts:
      - name: tenx-sockets
        mountPath: /tmp
      {{- if or .Values.tenx.github.config.enabled .Values.tenx.github.symbols.enabled }}
      - name: tenx-git
        mountPath: /etc/tenx/git
      {{- end }}
{{- end }}
{{- if or .Values.initContainers (and .Values.tenx.enabled (or .Values.tenx.github.config.enabled .Values.tenx.github.symbols.enabled)) }}
initContainers:
{{- if .Values.initContainers }}
  {{- tpl (toYaml .Values.initContainers) . | nindent 2 }}
{{- end }}
{{- if and .Values.tenx.enabled (or .Values.tenx.github.config.enabled .Values.tenx.github.symbols.enabled) }}
  - name: tenx-github-fetcher
    image: "{{ .Values.tenx.github.image.repository }}:{{ .Values.tenx.github.image.tag }}"
    imagePullPolicy: {{ .Values.tenx.github.image.pullPolicy }}
    env:
      {{- if .Values.tenx.github.config.enabled }}
      - name: CONFIG_ENABLED
        value: "true"
      - name: CONFIG_TOKEN
        value: {{ .Values.tenx.github.config.token | quote }}
      - name: CONFIG_REPO
        value: {{ .Values.tenx.github.config.repo | quote }}
      {{- if .Values.tenx.github.config.branch }}
      - name: CONFIG_BRANCH
        value: {{ .Values.tenx.github.config.branch | quote }}
      {{- end }}
      {{- end }}
      {{- if .Values.tenx.github.symbols.enabled }}
      - name: SYMBOLS_ENABLED
        value: "true"
      - name: SYMBOLS_TOKEN
        value: {{ .Values.tenx.github.symbols.token | quote }}
      - name: SYMBOLS_REPO
        value: {{ .Values.tenx.github.symbols.repo | quote }}
      {{- if .Values.tenx.github.symbols.branch }}
      - name: SYMBOLS_BRANCH
        value: {{ .Values.tenx.github.symbols.branch | quote }}
      {{- end }}
      {{- if .Values.tenx.github.symbols.path }}
      - name: SYMBOLS_PATH
        value: {{ .Values.tenx.github.symbols.path | quote }}
      {{- end }}
      {{- end }}
    volumeMounts:
      - name: tenx-git
        mountPath: /etc/tenx/git
{{- end }}
{{- end }}
{{- if .Values.priorityClassName }}
priorityClassName: {{ .Values.priorityClassName | quote }}
{{- end }}
{{- if .Values.runtimeClassName }}
runtimeClassName: {{ .Values.runtimeClassName | quote }}
{{- end }}
volumes:
  {{- if or .Values.configMap.create .Values.configMap.existingName }}
  - name: {{ include "opentelemetry-collector.lowercase_chartname" . }}-configmap
    configMap:
      name: {{ include "opentelemetry-collector.configName" . }}
      items:
        - key: relay
          path: relay.yaml
  {{- end }}
  {{- if or .Values.presets.logsCollection.enabled .Values.presets.annotationDiscovery.logs.enabled }}
  - name: varlogpods
    hostPath:
      path: /var/log/pods
  {{- if .Values.presets.logsCollection.storeCheckpoints}}
  - name: varlibotelcol
    hostPath:
      path: /var/lib/otelcol
      type: DirectoryOrCreate
  {{- end }}
  - name: varlibdockercontainers
    hostPath:
      path: /var/lib/docker/containers
  {{- end }}
  {{- if .Values.presets.hostMetrics.enabled }}
  - name: hostfs
    hostPath:
      path: /
  {{- end }}
{{- if .Values.tenx.enabled }}
  - name: tenx-sockets
    emptyDir: {}
  {{- if or .Values.tenx.github.config.enabled .Values.tenx.github.symbols.enabled }}
  - name: tenx-git
    emptyDir: {}
  {{- end }}
{{- end }}
  {{- if .Values.extraVolumes }}
  {{- tpl (toYaml .Values.extraVolumes) . | nindent 2 }}
  {{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
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
