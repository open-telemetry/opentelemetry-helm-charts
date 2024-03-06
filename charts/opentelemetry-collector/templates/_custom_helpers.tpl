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
