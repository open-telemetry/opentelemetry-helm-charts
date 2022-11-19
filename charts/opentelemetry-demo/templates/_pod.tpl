{{/*
Get Pod Env
Merges default environment variables (if used) with component environment variables.
If using defaults, will pull out OTEL_RESOURCE_ATTRIBUTES from the list and add it to the end.
The OTEL_RESOURCES_ATTRIBUTES environment variable uses Kubernetes environment variable expansion and should be last.
*/}}
{{- define "otel-demo.pod.env" -}}
{{- $resourceAttributesEnv := dict }}
{{- $allEnvs := list }}
{{- if .useDefault.env  }}
{{-   $defaultEnvs := include "otel-demo.envOverriden" (dict "env" .defaultValues.env "envOverrides" .defaultValues.envOverrides) | mustFromJson }}
{{-   range $defaultEnvs }}
{{-     if eq .name "OTEL_RESOURCE_ATTRIBUTES" }}
{{-       $resourceAttributesEnv = . }}
{{-     else }}
{{-       $allEnvs = append $allEnvs . }}
{{-     end }}
{{-   end }}
{{- end }}
{{- if or .env .envOverrides }}
{{-   $allEnvs = concat $allEnvs ((include "otel-demo.envOverriden" .) | mustFromJson) }}
{{- end }}
{{- if $resourceAttributesEnv }}
{{-   $allEnvs = append $allEnvs $resourceAttributesEnv }}
{{- end }}
{{- tpl (toYaml $allEnvs) . }}
{{- end }}

{{/*
Get Pod ports
*/}}
{{- define "otel-demo.pod.ports" -}}
{{- if .ports }}
{{- range $port := .ports }}
- containerPort: {{ $port.value }}
  name: {{ $port.name}}
{{- end }}
{{- end }}

{{- if .servicePort }}
- containerPort: {{.servicePort}}
  name: service
{{- end }}
{{- end }}
