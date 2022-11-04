{{/*
Get Pod Env
Note: Consider that dependent variables need to be declared before the referenced env variable.
*/}}
{{- define "otel-demo.pod.env" -}}
{{- if .useDefault.env  }}
{{ include "otel-demo.envOverriden" (dict "env" .defaultValues.env "envOverrides" .defaultValues.envOverrides "Template" $.Template) }}
{{- end }}

{{- if .env  }}
{{ include "otel-demo.envOverriden" . }}
{{- end }}

{{- end }}

{{/*
Get Pod Env
Note: Consider that dependent variables need to be declared before the referenced env variable.
*/}}
{{- define "otel-demo.pod.env3" -}}
  {{- $mergedDefaultEnvs := list }}
  {{- $defaultEnvOverrides := default (list) .defaultValues.envOverrides }}

  {{- if .useDefault.env  }}
    {{- range .defaultValues.env }}
      {{- $currentEnv := . }}
      {{- $hasOverride := false }}
      {{- range $defaultEnvOverrides }}
        {{- if eq $currentEnv.name .name }}
          {{- $mergedDefaultEnvs = append $mergedDefaultEnvs . }}
          {{- $defaultEnvOverrides = without $defaultEnvOverrides . }}
          {{- $hasOverride = true }}
        {{- end }}
      {{- end }}
      {{- if not $hasOverride }}
        {{- $mergedDefaultEnvs = append $mergedDefaultEnvs $currentEnv }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $mergedDefaultEnvs = concat $mergedDefaultEnvs $defaultEnvOverrides }}

  {{- $mergedEnvs := list }}
  {{- $envOverrides := default (list) .envOverrides }}

  {{- if .env  }}
    {{- range concat $mergedDefaultEnvs .env }}
      {{- $currentEnv := . }}
      {{- $hasOverride := false }}
      {{- range default (list) $envOverrides }}
        {{- if eq $currentEnv.name .name }}
          {{- $mergedEnvs = append $mergedEnvs . }}
          {{- $envOverrides = without $envOverrides . }}
          {{- $hasOverride = true }}
        {{- end }}
      {{- end }}
      {{- if not $hasOverride }}
        {{- $mergedEnvs = append $mergedEnvs $currentEnv }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $mergedEnvs = concat $mergedEnvs $envOverrides }}

  {{- tpl (toYaml $mergedEnvs) . }}
{{- end }}

{{/*
Get Pod Env
Note: Consider that dependent variables need to be declared before the referenced env variable.
*/}}
{{- define "otel-demo.pod.env2" -}}
{{- $mergedDefaultEnvs := list }}
{{- if .useDefault.env  }}
{{- $copyMap := dict }}
{{- range .defaultValues.env }}
{{- $_ := set $copyMap .name . }}
{{- end }}
{{- range .defaultValues.envOverrides }}
{{- $_ := set $copyMap .name . }}
{{- end }}
{{- range $key, $value := $copyMap }}
{{- $mergedDefaultEnvs = append $mergedDefaultEnvs $value }}
{{- end }}
{{- end }}

{{- $mergedEnvs := list }}
{{- if .env }}
{{- $copyMap := dict}}
{{- range (concat $mergedDefaultEnvs .env) }}
{{- $_ := set $copyMap .name . }}
{{- end }}
{{- range .envOverrides }}
{{- $_ := set $copyMap .name . }}
{{- end }}
{{- range $key, $value := $copyMap }}
{{- $mergedEnvs = append $mergedEnvs $value }}
{{- end }}
{{- end }}

{{- tpl (toYaml $mergedEnvs) . }}
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
