{{/*
Expand the name of the chart.
*/}}
{{- define "opentelemetry-kube-stack.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-kube-stack.fullname" -}}
{{- if .fullnameOverride }}
{{- .fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}


{{/*
Add the opamp labels if they're enabled
*/}}
{{- define "opentelemetry-kube-stack.collectorOpAMPLabels" -}}
{{- if and .opAMPBridge.enabled .opAMPBridge.addReportingLabel }}
opentelemetry.io/opamp-reporting: "true"
{{- end }}
{{- if and .opAMPBridge.enabled .opAMPBridge.addManagedLabel }}
opentelemetry.io/opamp-managed: "true"
{{- end }}
{{- end }}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "opentelemetry-kube-stack.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Print a map of key values in a YAML block. This is useful for labels and annotations.
*/}}
{{- define "opentelemetry-kube-stack.renderkv" -}}
{{- with . -}}
{{- range $key, $value := . -}}
{{- printf "\n%s: %s" $key $value }}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Render a deduped list of environment variables and 'extraEnvs'
*/}}
{{- define "opentelemetry-kube-stack.renderenvs" -}}
{{- $envMap := dict }}
{{- $valueFromMap := dict }}
{{- range $item := .extraEnvs }}
{{- if $item.value }}
{{- $_ := set $envMap $item.name $item.value }}
{{- else }}
{{- $_ := set $valueFromMap $item.name $item.valueFrom }}
{{- end }}
{{- end }}
{{- range $item := .env }}
{{- if $item.value }}
{{- $_ := set $envMap $item.name $item.value }}
{{- else }}
{{- $_ := set $valueFromMap $item.name $item.valueFrom }}
{{- end }}
{{- end }}
{{- range $key, $value := $envMap }}
- name: {{ $key }}
  value: {{ $value }}
{{- end }}
{{- range $key, $value := $valueFromMap }}
- name: {{ $key }}
  valueFrom:
    {{- $value | toYaml | nindent 4 }}
{{- end }}
{{- end }}

{{/*
Create the name of the instrumentation to use
*/}}
{{- define "opentelemetry-kube-stack.instrumentation" -}}
{{- default .Release.Name .Values.instrumentation.name }}
{{- end }}

{{/*
Create the name of the bridge to create
*/}}
{{- define "opentelemetry-opamp-bridge.fullname" -}}
{{- default .Release.Name .opAMPBridge.name }}
{{- end }}

{{/*
Create the name of the clusterRole to use for the opampbridge
*/}}
{{- define "opentelemetry-opamp-bridge.clusterRoleName" -}}
{{- default (printf "%s-bridge" .Release.Name) .Values.opAMPBridge.clusterRole.name }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "opentelemetry-kube-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opentelemetry-kube-stack.labels" -}}
helm.sh/chart: {{ include "opentelemetry-kube-stack.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
release: {{ .Release.Name | quote }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opentelemetry-kube-stack.collectorFullname" -}}
{{- if .fullnameOverride }}
{{- .fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if .collector.fullnameOverride }}
{{- .collector.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $suffix := default .Chart.Name (coalesce .collector.suffix "") }}
{{- if contains $suffix .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $suffix | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create the name of the clusterRole to use
*/}}
{{- define "opentelemetry-kube-stack.clusterRoleName" -}}
{{- default (printf "%s-collector" .Release.Name) .Values.clusterRole.name }}
{{- end }}

{{/*
Create the name of the clusterRoleBinding to use
*/}}
{{- define "opentelemetry-kube-stack.clusterRoleBindingName" -}}
{{- default (include "opentelemetry-kube-stack.fullname" .) .Values.clusterRole.clusterRoleBinding.name }}
{{- end }}

{{/*
Optionally include the RBAC for the k8sCluster receiver
*/}}
{{- define "opentelemetry-kube-stack.k8scluster.rules" -}}
{{- if $.Values.clusterRole.rules }}
{{ toYaml $.Values.clusterRole.rules }}
{{- end }}
{{- $clusterMetricsEnabled := false }}
{{- $eventsEnabled := false }}
{{- $useLeaderElection := false }}
{{ range $_, $collector := $.Values.collectors -}}
{{- $clusterMetricsEnabled = (any $clusterMetricsEnabled (dig "config" "receivers" "k8s_cluster" false $collector)) }}
{{- if (dig "presets" "clusterMetrics" "enabled" false $collector) }}
{{- $clusterMetricsEnabled = true }}
{{- $useLeaderElection = (any $useLeaderElection (not (dig "presets" "clusterMetrics" "disableLeaderElection" false $collector))) }}
{{- end }}
{{- $eventsEnabled = (any $eventsEnabled (dig "config" "receivers" "k8s_cluster" false $collector)) }}
{{- if (dig "presets" "kubernetesEvents" "enabled" false $collector) }}
{{- $eventsEnabled = true }}
{{- $useLeaderElection = (any $useLeaderElection (not (dig "presets" "kubernetesEvents" "disableLeaderElection" false $collector))) }}
{{- end }}
{{- end }}
{{- if $useLeaderElection }}
- verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
  - delete
  apiGroups:
  - coordination.k8s.io
  resources:
  - leases
{{- end }}
{{- if $clusterMetricsEnabled }}
- apiGroups:
  - ""
  resources:
  - events
  - namespaces
  - namespaces/status
  - nodes
  - nodes/spec
  - pods
  - pods/status
  - replicationcontrollers
  - replicationcontrollers/status
  - resourcequotas
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - apps
  resources:
  - daemonsets
  - deployments
  - replicasets
  - statefulsets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - extensions
  resources:
  - daemonsets
  - deployments
  - replicasets
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - batch
  resources:
  - jobs
  - cronjobs
  verbs:
  - get
  - list
  - watch
- apiGroups:
    - autoscaling
  resources:
    - horizontalpodautoscalers
  verbs:
    - get
    - list
    - watch
{{- end }}
{{- if $eventsEnabled }}
- apiGroups: ["events.k8s.io"]
  resources: ["events"]
  verbs: ["watch", "list"]
{{- end }}
{{- end }}

{{/*
Helpers for prometheus servicemonitors
*/}}
{{/* Prometheus specific stuff. */}}
{{/* Allow KubeVersion to be overridden. */}}
{{- define "opentelemetry-kube-stack.kubeVersion" -}}
  {{- default .Capabilities.KubeVersion.Version .Values.kubeVersionOverride -}}
{{- end -}}

{{/* Get value based on current Kubernetes version */}}
{{- define "opentelemetry-kube-stack.kubeVersionDefaultValue" -}}
  {{- $values := index . 0 -}}
  {{- $kubeVersion := index . 1 -}}
  {{- $old := index . 2 -}}
  {{- $new := index . 3 -}}
  {{- $default := index . 4 -}}
  {{- if kindIs "invalid" $default -}}
    {{- if semverCompare $kubeVersion (include "opentelemetry-kube-stack.kubeVersion" $values) -}}
      {{- print $new -}}
    {{- else -}}
      {{- print $old -}}
    {{- end -}}
  {{- else -}}
    {{- print $default }}
  {{- end -}}
{{- end -}}

{{/* Get value for kube-controller-manager depending on insecure scraping availability */}}
{{- define "opentelemetry-kube-stack.kubeControllerManager.insecureScrape" -}}
  {{- $values := index . 0 -}}
  {{- $insecure := index . 1 -}}
  {{- $secure := index . 2 -}}
  {{- $userValue := index . 3 -}}
  {{- include "opentelemetry-kube-stack.kubeVersionDefaultValue" (list $values ">= 1.22-0" $insecure $secure $userValue) -}}
{{- end -}}

{{/* Get value for kube-scheduler depending on insecure scraping availability */}}
{{- define "opentelemetry-kube-stack.kubeScheduler.insecureScrape" -}}
  {{- $values := index . 0 -}}
  {{- $insecure := index . 1 -}}
  {{- $secure := index . 2 -}}
  {{- $userValue := index . 3 -}}
  {{- include "opentelemetry-kube-stack.kubeVersionDefaultValue" (list $values ">= 1.23-0" $insecure $secure $userValue) -}}
{{- end -}}

{{/* Sets default scrape limits for servicemonitor */}}
{{- define "opentelemetry-kube-stack.servicemonitor.scrapeLimits" -}}
{{- with .sampleLimit }}
sampleLimit: {{ . }}
{{- end }}
{{- with .targetLimit }}
targetLimit: {{ . }}
{{- end }}
{{- with .labelLimit }}
labelLimit: {{ . }}
{{- end }}
{{- with .labelNameLengthLimit }}
labelNameLengthLimit: {{ . }}
{{- end }}
{{- with .labelValueLengthLimit }}
labelValueLengthLimit: {{ . }}
{{- end }}
{{- end -}}

{{/* To help configure the kubelet servicemonitor for http or https. */}}
{{- define "opentelemetry-kube-stack.kubelet.scheme" }}
{{- if .Values.kubelet.serviceMonitor.https }}https{{ else }}http{{ end }}
{{- end }}
{{- define "opentelemetry-kube-stack.kubelet.authConfig" }}
{{- if .Values.kubelet.serviceMonitor.https }}
tlsConfig:
  caFile: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
  insecureSkipVerify: {{ .Values.kubelet.serviceMonitor.insecureSkipVerify }}
bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
{{- end }}
{{- end }}
