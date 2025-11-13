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
Determine the container image to use based on presets and user overrides.
*/}}
{{- define "opentelemetry-collector.image" }}
{{- $imageRepository := "ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-contrib" }}
{{- $imageTag := .Chart.AppVersion }}
{{- if (and (.Values.presets.fleetManagement.enabled) (.Values.presets.fleetManagement.supervisor.enabled) (not .Values.collectorCRD.generate)) }}
{{- $imageRepository = "cgx.jfrog.io/coralogix-docker-images/otel-supervised-collector" }}
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
{{- /* Step 1: If on Windows, the executable path is different */ -}}
{{- if .Values.isWindows -}}
{{- $executable = "C:\\otelcol-contrib.exe" | quote -}}
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
{{- if .Values.presets.profilesCollection.enabled }}
- "--feature-gates=+service.profilesSupport"
{{- end }}
{{- range .Values.command.extraArgs }}
- {{ . }}
{{- end }}
{{- end }}

{{/*
Generate default OTEL_RESOURCE_ATTRIBUTES value when resourceDetection preset is enabled.
*/}}
{{- define "opentelemetry-collector.defaultResourceAttributes" -}}
{{- $attrs := list }}
{{- if and .Values.presets.resourceDetection.enabled .Values.presets.resourceDetection.k8sNodeName.enabled -}}
{{-   $attrs = append $attrs "k8s.node.name=$(K8S_NODE_NAME)" -}}
{{- end -}}
{{- $deploymentEnvName := .Values.presets.resourceDetection.deploymentEnvironmentName | default .Values.global.deploymentEnvironmentName | default .Values.global.clusterName }}
{{- with $deploymentEnvName }}
{{-   $val := tpl . $ -}}
{{-   if ne $val "" -}}
{{-     $attrs = append $attrs (printf "deployment.environment.name=%s" $val) -}}
{{-   end -}}
{{- end -}}
{{- join "," $attrs -}}
{{- end -}}

{{/*
Return pod or node IP environment variable wrapped for IPv6 when required.*/}}
{{- define "opentelemetry-collector.envHost" -}}
{{- /* When running in ECS mode, there is no MY_POD_IP env, use 0.0.0.0 in generated config */ -}}
{{- if and (eq .env "MY_POD_IP") (or (eq .context.Values.distribution "ecs") (eq .context.Values.distribution "standalone")) -}}
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
Compose endpoint from IP environment variable and port taking networkMode into account.*/}}
{{- define "opentelemetry-collector.envEndpoint" -}}
{{- $host := include "opentelemetry-collector.envHost" (dict "env" .env "context" .context) -}}
{{ printf "%s:%s" $host .port }}
{{- end -}}
