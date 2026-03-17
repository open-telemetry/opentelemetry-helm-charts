{{/*
Create an identifier for multiline logs configuration.
*/}}
{{- define "opentelemetry-collector.newlineKey" }}
{{- $key := "" }}
{{- if .namespaceName }}
{{- $key = printf "%s_" .namespaceName.value }}
{{- end }}

{{- if .podName }}
{{- $key = printf "%s%s_" $key .podName.value }}
{{- end }}
{{- if .containerName }}
{{- $key = printf "%s%s" $key .containerName.value }}
{{- end }}
{{- $key | trimSuffix "_" }}
{{- end -}}

{{/*
Create a filter expression for multiline logs configuration.
*/}}
{{- define "opentelemetry-collector.newlineExpr" }}
{{- $expr := "" }}
{{- if .namespaceName }}
{{- $useRegex := eq (toString .namespaceName.useRegex | default "false") "true" }}
{{- $expr = cat "(resource[\"k8s.namespace.name\"])" (ternary "matches" "==" $useRegex) (quote .namespaceName.value) "&&" }}
{{- end }}
{{- if .podName }}
{{- $useRegex := eq (toString .podName.useRegex | default "false") "true" }}
{{- $expr = cat $expr "(resource[\"k8s.pod.name\"])" (ternary "matches" "==" $useRegex) (quote .podName.value) "&&" }}
{{- end }}
{{- if .containerName }}
{{- $useRegex := eq (toString .containerName.useRegex | default "false") "true" }}
{{- $expr = cat $expr "(resource[\"k8s.container.name\"])" (ternary "matches" "==" $useRegex) (quote .containerName.value) "&&" }}
{{- end }}
{{- $expr | trimSuffix "&&" | trim }}
{{- end -}}

{{/*
AWS cloud detectors for resourcedetection.
Input: dict with distribution, mode, isK8s, provider, resourceDetectionEnabled (for catalog - when false, K8s Deployment/StatefulSet uses ec2/eks fallback)
Returns: comma-separated detector names (e.g. "ec2,eks") to avoid fromJson type issues
*/}}
{{- define "opentelemetry-collector.awsCloudDetectors" -}}
{{- $distribution := .distribution | default "" }}
{{- $mode := .mode | default "daemonset" }}
{{- $isK8s := .isK8s }}
{{- $provider := .provider }}
{{- $resourceDetectionEnabled := true }}
{{- if hasKey . "resourceDetectionEnabled" }}
{{- $resourceDetectionEnabled = .resourceDetectionEnabled }}
{{- end }}
{{- $detectors := list -}}
{{- if eq $provider "aws" }}
  {{- if eq $distribution "eks/fargate" }}
    {{- $detectors = (list "env") }}
  {{- else if eq $distribution "standalone" }}
    {{- $detectors = (list "ec2") }}
  {{- else if eq $distribution "ecs" }}
    {{/* ECS on EC2: daemon with host network, IMDS accessible */}}
    {{- $detectors = (list "ec2") }}
  {{- else if and $isK8s (eq $mode "daemonset") }}
    {{- if hasPrefix "eks" $distribution }}
      {{- $detectors = (list "ec2" "eks") }}
    {{- else if eq $distribution "" }}
      {{/* Self-managed K8s on AWS: ec2 only, no EKS detector */}}
      {{- $detectors = (list "ec2") }}
    {{- else }}
      {{- $detectors = (list "ec2") }}
    {{- end }}
  {{- else if $isK8s }}
    {{- if $resourceDetectionEnabled }}
      {{- $detectors = (list "env") }}
    {{- else }}
      {{- if or (hasPrefix "eks" $distribution) (eq $distribution "") }}
        {{- $detectors = (list "ec2" "eks") }}
      {{- else }}
        {{- $detectors = (list "ec2") }}
      {{- end }}
    {{- end }}
  {{- else }}
    {{- $detectors = (list "ec2") }}
  {{- end }}
{{- end }}
{{- if gt (len $detectors) 0 }}{{ join "," $detectors }}{{- end -}}
{{- end -}}

{{/*
Determine the container image to use based on presets and user overrides.
*/}}
{{- define "opentelemetry-collector.image" }}
{{- $imageRepository := "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib" }}
{{- $imageTag := .Chart.AppVersion }}
{{- if (and (.Values.presets.fleetManagement.enabled) (.Values.presets.fleetManagement.supervisor.enabled) (not .Values.collectorCRD.generate)) }}
{{- $imageRepository = "cgx.jfrog.io/coralogix-docker-images/coralogix-otel-supervised-collector" }}
{{- end }}
{{- if .Values.presets.ebpfProfiler.enabled }}
{{- $imageRepository = "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-ebpf-profiler" }}
{{- end }}
{{- if .Values.image.repository }}
{{- $imageRepository = .Values.image.repository }}
{{- end }}
{{- if .Values.image.tag }}
{{- $imageTag = .Values.image.tag }}
{{- end }}
{{- if .Values.image.digest }}
{{- printf "%s@%s" $imageRepository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" $imageRepository $imageTag }}
{{- end }}
{{- end }}

{{/*
Determine the command to use based on platform and configuration.
*/}}
{{- define "opentelemetry-collector.command" -}}
{{- $executable := "/otelcol-contrib" -}}
{{- $configPath := "/conf/relay.yaml" -}}
{{- $configArg := "" -}}
{{- $profilesSupportEnabled := or .Values.presets.profilesCollection.enabled .Values.presets.ebpfProfiler.enabled -}}
{{- $profilesGateAlreadySet := false -}}
{{- range .Values.command.extraArgs -}}
  {{- if contains "service.profilesSupport" . -}}
    {{- $profilesGateAlreadySet = true -}}
  {{- end -}}
{{- end -}}
{{- /* Step 1: If on Windows, the executable path is different */ -}}
{{- if .Values.isWindows -}}
{{- $executable = "C:\\otelcol-contrib.exe" | quote -}}
{{- end -}}
{{- if and .Values.presets.ebpfProfiler.enabled (not .Values.isWindows) -}}
{{- $executable = "/otelcol-ebpf-profiler" -}}
{{- end -}}
{{- if (and (.Values.presets.fleetManagement.enabled) (.Values.presets.fleetManagement.supervisor.enabled)) -}}
{{- $executable = "/opampsupervisor" }}
{{- end -}}
{{- if .Values.command.name -}}
{{- $executable = printf "/%s" .Values.command.name -}}
{{- end -}}
{{- /* Step 2: Determine config path and argument based on configuration */ -}}
{{- if .Values.configMap.create -}}
{{- if .Values.isWindows -}}
{{- $configPath = `C:\\conf\relay.yaml` -}}
{{- end -}}
{{- if (and (.Values.presets.fleetManagement.enabled) (.Values.presets.fleetManagement.supervisor.enabled)) -}}
{{- $configPath = "/etc/otelcol-contrib/supervisor.yaml" -}}
{{- end -}}
{{- $configArg = printf "--config=%s" $configPath -}}
{{- end -}}
{{- /* Step 3: Build the command array */ -}}
- {{ $executable }}
{{- if $configArg }}
- {{ $configArg }}
{{- end }}
{{- if and $profilesSupportEnabled (not .Values.presets.fleetManagement.supervisor.enabled) (not $profilesGateAlreadySet) }}
- --feature-gates=+service.profilesSupport
{{- end }}
{{- if not .Values.presets.fleetManagement.supervisor.enabled }}
{{- range .Values.command.extraArgs }}
- {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate default OTEL_RESOURCE_ATTRIBUTES value when resourceDetection preset is enabled.
*/}}
{{- define "opentelemetry-collector.defaultResourceAttributes" -}}
{{- $attrs := list -}}
{{- if .Values.presets.resourceDetection.enabled -}}
{{- if .Values.presets.resourceDetection.k8sNodeName.enabled -}}
{{- $attrs = append $attrs "k8s.node.name=$(K8S_NODE_NAME)" -}}
{{- end -}}
{{- $deploymentEnvName := .Values.presets.resourceDetection.deploymentEnvironmentName | default .Values.global.deploymentEnvironmentName | default .Values.global.clusterName -}}
{{- with $deploymentEnvName -}}
{{- $val := tpl . $ -}}
{{- if ne $val "" -}}
{{- $attrs = append $attrs (printf "deployment.environment.name=%s" $val) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $distribution := .Values.distribution | default "" -}}
{{- $provider := include "opentelemetry-collector.inferProvider" (dict "distribution" $distribution "topLevelProvider" .Values.provider "explicitProvider" .Values.presets.resourceDetection.provider) -}}
{{- $isK8s := and (ne $distribution "standalone") (ne $distribution "ecs") (ne $distribution "macos") -}}
{{- $needsCloudAttrs := false -}}
{{- $cloudPlatform := "" -}}
{{- if and .Values.presets.resourceDetection.enabled (eq $provider "aws") -}}
{{- if eq $distribution "eks/fargate" -}}
{{- $needsCloudAttrs = true -}}
{{- $cloudPlatform = "aws_eks" -}}
{{- else if eq $distribution "ecs" -}}
{{- $needsCloudAttrs = true -}}
{{- $cloudPlatform = "aws_ecs" -}}
{{- else if and $isK8s (ne .Values.mode "daemonset") -}}
{{- $needsCloudAttrs = true -}}
{{- if hasPrefix "eks" $distribution -}}
{{- $cloudPlatform = "aws_eks" -}}
{{- else -}}
{{- $cloudPlatform = "aws_ec2" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $userSetCloudDetectors := and .Values.presets.resourceDetection.detectors .Values.presets.resourceDetection.detectors.cloud (gt (len .Values.presets.resourceDetection.detectors.cloud) 0) -}}
{{- if and $needsCloudAttrs (not $userSetCloudDetectors) -}}
{{- $attrs = append $attrs "cloud.provider=aws" -}}
{{- $attrs = append $attrs (printf "cloud.platform=%s" $cloudPlatform) -}}
{{- end -}}
{{- join "," $attrs -}}
{{- end -}}

{{/*
Return pod or node IP environment variable wrapped for IPv6 when required.*/}}
{{- define "opentelemetry-collector.envHost" -}}
{{- /* When running in standalone or macOS mode, use OTEL_LISTEN_INTERFACE with 127.0.0.1 fallback */ -}}
{{- if and (eq .env "MY_POD_IP") (or (eq .context.Values.distribution "standalone") (eq .context.Values.distribution "macos")) -}}
${env:OTEL_LISTEN_INTERFACE:-127.0.0.1}
{{- /* When running in ECS mode there is no MY_POD_IP env, use 0.0.0.0 in generated config */ -}}
{{- else if and (eq .env "MY_POD_IP") (eq .context.Values.distribution "ecs") -}}
0.0.0.0
{{- else -}}
  {{- $ip := printf "${env:%s}" .env -}}
  {{- if eq .context.Values.networkMode "ipv6" -}}
  {{ printf "[%s]" $ip }}
  {{- else -}}
  {{ $ip }}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Status code OTTL statements for span metrics.
This helper provides the status code transformation statements that are used
by both the spanMetrics and spanMetricsMulti presets.
*/}}
{{- define "opentelemetry-collector.spanMetricsStatusCodeStatements" -}}
- set(attributes["status.code"], "STATUS_CODE_ERROR") where attributes["status.code"] == nil and instrumentation_scope.name == "spanmetricsconnector" and attributes["otel.status_code"] == "ERROR"
- set(attributes["status.code"], "STATUS_CODE_OK") where attributes["status.code"] == nil and instrumentation_scope.name == "spanmetricsconnector" and attributes["otel.status_code"] == "OK"
- set(attributes["status.code"], "STATUS_CODE_UNSET") where attributes["status.code"] == nil and instrumentation_scope.name == "spanmetricsconnector" and (attributes["otel.status_code"] == "UNSET" or attributes["otel.status_code"] == nil)
{{- end -}}

{{/*
Compose endpoint from IP environment variable and port taking networkMode into account.*/}}
{{- define "opentelemetry-collector.envEndpoint" -}}
{{- $host := include "opentelemetry-collector.envHost" (dict "env" .env "context" .context) -}}
{{ printf "%s:%s" $host .port }}
{{- end -}}

{{/*
Generate health_check endpoint based on distribution.
For standalone/macos distributions, uses OTEL_LISTEN_INTERFACE with 127.0.0.1 fallback.
For other distributions, uses MY_POD_IP environment variable.
*/}}
{{- define "opentelemetry-collector.healthCheckEndpoint" -}}
{{- if or (eq .Values.distribution "standalone") (eq .Values.distribution "macos") -}}
${env:OTEL_LISTEN_INTERFACE:-127.0.0.1}:13133
{{- else -}}
${env:MY_POD_IP}:13133
{{- end -}}
{{- end -}}
