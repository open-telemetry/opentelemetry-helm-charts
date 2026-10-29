{{/*
Get Pod Annotations
- Merges default pod annotations with component pod annotations, component values take precedence.
- Default annotation values are rendered as templates, component annotation values are used as is.
*/}}
{{- define "otel-demo.pod.annotations" -}}
{{- $annotations := dict }}
{{- range $key, $value := (.defaultValues.podAnnotations | default dict) }}
{{-   $_ := set $annotations $key (tpl (toString $value) $) }}
{{- end }}
{{- range $key, $value := (.podAnnotations | default dict) }}
{{-   $_ := set $annotations $key (toString $value) }}
{{- end }}
{{- toJson $annotations }}
{{- end }}

{{/*
Get Pod Env
- Merges default environment variables (if used) with component environment variables.
- If using defaults, will pull out OTEL_RESOURCE_ATTRIBUTES from the list to be reused later.
- If using defaults, each `resource.opentelemetry.io/` pod annotation (except service.name, which is used by
OTEL_SERVICE_NAME) is exposed through the downward API as an environment variable, and these are combined into the
OTEL_RESOURCE_ATTRIBUTES_ANNOTATIONS environment variable.
- OTEL_RESOURCE_ATTRIBUTES is set to OTEL_RESOURCE_ATTRIBUTES_ANNOTATIONS, followed by the value of any configured
OTEL_RESOURCE_ATTRIBUTES, followed by the value of an environment variable named OTEL_RESOURCE_ATTRIBUTES_EXTRA.
- A configured OTEL_RESOURCE_ATTRIBUTES that uses valueFrom is kept as is, along with OTEL_RESOURCE_ATTRIBUTES_EXTRA.
- The OTEL_RESOURCES_ATTRIBUTES environment variable will typically use Kubernetes environment variable expansion and
should be last.
*/}}
{{- define "otel-demo.pod.env" -}}
{{- $resourceAttributesEnv := dict }}
{{- $resourceAttributesExtraEnv := dict }}
{{- $annotationAttributes := list }}
{{- $allEnvs := list }}

{{- if .useDefault.env  }}
{{-   range $key, $value := .resourceAnnotations }}
{{-     $attribute := trimPrefix "resource.opentelemetry.io/" $key }}
{{-     if and (hasPrefix "resource.opentelemetry.io/" $key) (ne $attribute "service.name") }}
{{-       $envName := printf "OTEL_RESOURCE_ATTR_%s" (regexReplaceAll "[^A-Za-z0-9]" $attribute "_" | upper) }}
{{-       $fieldRef := dict "apiVersion" "v1" "fieldPath" (printf "metadata.annotations['%s']" $key) }}
{{-       $allEnvs = append $allEnvs (dict "name" $envName "valueFrom" (dict "fieldRef" $fieldRef)) }}
{{-       $annotationAttributes = append $annotationAttributes (printf "%s=$(%s)" $attribute $envName) }}
{{-     end }}
{{-   end }}
{{-   if $annotationAttributes }}
{{-     $allEnvs = append $allEnvs (dict "name" "OTEL_RESOURCE_ATTRIBUTES_ANNOTATIONS" "value" (join "," $annotationAttributes)) }}
{{-   end }}
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
{{-   $localEnvs := include "otel-demo.envOverriden" . | mustFromJson }}
{{-   range $localEnvs }}
{{-     if eq .name "OTEL_RESOURCE_ATTRIBUTES" }}
{{-       $resourceAttributesEnv = . }}
{{-     else if eq .name "OTEL_RESOURCE_ATTRIBUTES_EXTRA" }}
{{-       $resourceAttributesExtraEnv = . }}
{{-     else }}
{{-       $allEnvs = append $allEnvs . }}
{{-     end }}
{{-   end }}
{{- end }}

{{- if $resourceAttributesEnv.valueFrom }}
{{-   with $resourceAttributesExtraEnv }}
{{-     $allEnvs = append $allEnvs . }}
{{-   end }}
{{-   $allEnvs = append $allEnvs $resourceAttributesEnv }}
{{- else }}
{{-   $resourceAttributes := list }}
{{-   if $annotationAttributes }}
{{-     $resourceAttributes = append $resourceAttributes "$(OTEL_RESOURCE_ATTRIBUTES_ANNOTATIONS)" }}
{{-   end }}
{{-   with $resourceAttributesEnv.value }}
{{-     $resourceAttributes = append $resourceAttributes . }}
{{-   end }}
{{-   with $resourceAttributesExtraEnv.value }}
{{-     $resourceAttributes = append $resourceAttributes . }}
{{-   end }}
{{-   if $resourceAttributes }}
{{-     $allEnvs = append $allEnvs (dict "name" "OTEL_RESOURCE_ATTRIBUTES" "value" (join "," $resourceAttributes)) }}
{{-   end }}
{{- end }}

{{- tpl (toYaml $allEnvs) . }}
{{- end }}


{{/*
Get Pod ports
*/}}
{{- define "otel-demo.pod.ports" -}}
{{- if .ports }}
{{-   range $port := .ports }}
- containerPort: {{ $port.value }}
  name: {{ $port.name}}
{{-   end }}
{{- end }}
{{- if .service }}
{{-   if .service.port }}
- containerPort: {{.service.port}}
  name: service
{{-   end }}
{{- end }}
{{- end }}
