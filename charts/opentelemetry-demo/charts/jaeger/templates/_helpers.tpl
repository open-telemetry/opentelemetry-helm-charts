{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "jaeger.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "jaeger.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "jaeger.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "jaeger.labels" -}}
helm.sh/chart: {{ include "jaeger.chart" . }}
{{ include "jaeger.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "jaeger.selectorLabels" -}}
app.kubernetes.io/name: {{ include "jaeger.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the cassandra schema service account to use
*/}}
{{- define "jaeger.cassandraSchema.serviceAccountName" -}}
{{- if .Values.schema.serviceAccount.create -}}
  {{ default (printf "%s-cassandra-schema" (include "jaeger.fullname" .)) .Values.schema.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.schema.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the spark service account to use
*/}}
{{- define "jaeger.spark.serviceAccountName" -}}
{{- if .Values.spark.serviceAccount.create -}}
  {{ default (printf "%s-spark" (include "jaeger.fullname" .)) .Values.spark.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.spark.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the esIndexCleaner service account to use
*/}}
{{- define "jaeger.esIndexCleaner.serviceAccountName" -}}
{{- if .Values.esIndexCleaner.serviceAccount.create -}}
  {{ default (printf "%s-es-index-cleaner" (include "jaeger.fullname" .)) .Values.esIndexCleaner.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.esIndexCleaner.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the esRollover service account to use
*/}}
{{- define "jaeger.esRollover.serviceAccountName" -}}
{{- if .Values.esRollover.serviceAccount.create -}}
  {{ default (printf "%s-es-rollover" (include "jaeger.fullname" .)) .Values.esRollover.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.esRollover.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the esLookback service account to use
*/}}
{{- define "jaeger.esLookback.serviceAccountName" -}}
{{- if .Values.esLookback.serviceAccount.create -}}
  {{ default (printf "%s-es-lookback" (include "jaeger.fullname" .)) .Values.esLookback.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.esLookback.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the hotrod service account to use
*/}}
{{- define "jaeger.hotrod.serviceAccountName" -}}
{{- if .Values.hotrod.serviceAccount.create -}}
  {{ default (printf "%s-hotrod" (include "jaeger.fullname" .)) .Values.hotrod.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.hotrod.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the query service account to use
*/}}
{{- define "jaeger.query.serviceAccountName" -}}
{{- if .Values.query.serviceAccount.create -}}
  {{ default (include "jaeger.query.name" .) .Values.query.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.query.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the agent service account to use
*/}}
{{- define "jaeger.agent.serviceAccountName" -}}
{{- if .Values.agent.serviceAccount.create -}}
  {{ default (include "jaeger.agent.name" .) .Values.agent.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.agent.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the collector service account to use
*/}}
{{- define "jaeger.collector.serviceAccountName" -}}
{{- if .Values.collector.serviceAccount.create -}}
  {{ default (include "jaeger.collector.name" .) .Values.collector.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.collector.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the collector ingress host
*/}}
{{- define "jaeger.collector.ingressHost" -}}
{{- if (kindIs "string" .) }}
  {{- . }}
{{- else }}
  {{- .host }}
{{- end }}
{{- end -}}

{{/*
Create the collector ingress servicePort
*/}}
{{- define "jaeger.collector.ingressServicePort" -}}
{{- if (kindIs "string" .context) }}
  {{- .defaultServicePort }}
{{- else }}
  {{- .context.servicePort }}
{{- end }}
{{- end -}}

{{/*
Create the name of the ingester service account to use
*/}}
{{- define "jaeger.ingester.serviceAccountName" -}}
{{- if .Values.ingester.serviceAccount.create -}}
  {{ default (include "jaeger.ingester.name" .) .Values.ingester.serviceAccount.name }}
{{- else -}}
  {{ default "default" .Values.ingester.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified query name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.query.name" -}}
{{- $nameGlobalOverride := printf "%s-query" (include "jaeger.fullname" .) -}}
{{- if .Values.query.fullnameOverride -}}
{{- printf "%s" .Values.query.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified agent name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.agent.name" -}}
{{- $nameGlobalOverride := printf "%s-agent" (include "jaeger.fullname" .) -}}
{{- if .Values.agent.fullnameOverride -}}
{{- printf "%s" .Values.agent.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified collector name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.collector.name" -}}
{{- $nameGlobalOverride := printf "%s-collector" (include "jaeger.fullname" .) -}}
{{- if .Values.collector.fullnameOverride -}}
{{- printf "%s" .Values.collector.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a fully qualified ingester name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "jaeger.ingester.name" -}}
{{- $nameGlobalOverride := printf "%s-ingester" (include "jaeger.fullname" .) -}}
{{- if .Values.ingester.fullnameOverride -}}
{{- printf "%s" .Values.ingester.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $nameGlobalOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "cassandra.host" -}}
{{- if .Values.provisionDataStore.cassandra -}}
{{- if .Values.storage.cassandra.nameOverride }}
{{- printf "%s" .Values.storage.cassandra.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name "cassandra" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- else }}
{{- .Values.storage.cassandra.host }}
{{- end -}}
{{- end -}}

{{- define "cassandra.contact_points" -}}
{{- $port := .Values.storage.cassandra.port | toString }}
{{- if .Values.provisionDataStore.cassandra -}}
{{- if .Values.storage.cassandra.nameOverride }}
{{- $host := printf "%s" .Values.storage.cassandra.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- printf "%s:%s" $host $port }}
{{- else }}
{{- $host := printf "%s-%s" .Release.Name "cassandra" | trunc 63 | trimSuffix "-" -}}
{{- printf "%s:%s" $host $port }}
{{- end -}}
{{- else }}
{{- printf "%s:%s" .Values.storage.cassandra.host $port }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "elasticsearch.client.url" -}}
{{- $port := .Values.storage.elasticsearch.port | toString -}}
{{- $host := .Values.storage.elasticsearch.host }}
{{- if .Values.provisionDataStore.elasticsearch }}
{{- $host = printf "%s-elasticsearch" .Release.Name }}
{{- end }}
{{- printf "%s://%s:%s" .Values.storage.elasticsearch.scheme $host $port }}
{{- end -}}

{{- define "jaeger.hotrod.tracing.host" -}}
{{- default (include "jaeger.agent.name" .) .Values.hotrod.tracing.host -}}
{{- end -}}


{{/*
Configure list of IP CIDRs allowed access to load balancer (if supported)
*/}}
{{- define "loadBalancerSourceRanges" -}}
{{- if .service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
  {{- range $cidr := .service.loadBalancerSourceRanges }}
    - {{ $cidr }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "helm-toolkit.utils.joinListWithComma" -}}
{{- $local := dict "first" true -}}
{{- range $k, $v := . -}}{{- if not $local.first -}},{{- end -}}{{- $v -}}{{- $_ := set $local "first" false -}}{{- end -}}
{{- end -}}


{{/*
Cassandra related environment variables
*/}}
{{- define "cassandra.env" -}}
- name: CASSANDRA_SERVERS
  value: {{ include "cassandra.host" . }}
- name: CASSANDRA_PORT
  value: {{ .Values.storage.cassandra.port | quote }}
{{ if .Values.storage.cassandra.tls.enabled }}
- name: CASSANDRA_TLS_ENABLED
  value: "true"
- name: CASSANDRA_TLS_SERVER_NAME
  valueFrom:
    secretKeyRef:
      name: {{ .Values.storage.cassandra.tls.secretName }}
      key: commonName
- name: CASSANDRA_TLS_KEY
  value: "/cassandra-tls/client-key.pem"
- name: CASSANDRA_TLS_CERT
  value: "/cassandra-tls/client-cert.pem"
- name: CASSANDRA_TLS_CA
  value: "/cassandra-tls/ca-cert.pem"
{{- end }}
{{- if .Values.storage.cassandra.keyspace }}
- name: CASSANDRA_KEYSPACE
  value: {{ .Values.storage.cassandra.keyspace }}
{{- end }}
- name: CASSANDRA_USERNAME
  value: {{ .Values.storage.cassandra.user }}
- name: CASSANDRA_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.storage.cassandra.existingSecret }}{{ .Values.storage.cassandra.existingSecret }}{{- else }}{{ include "jaeger.fullname" . }}-cassandra{{- end }}
      key: password
{{- range $key, $value := .Values.storage.cassandra.env }}
- name: {{ $key | quote }}
  value: {{ $value | quote }}
{{ end -}}
{{- if .Values.storage.cassandra.extraEnv }}
{{ toYaml .Values.storage.cassandra.extraEnv }}
{{- end }}
{{- end -}}

{{/*
Elasticsearch related environment variables
*/}}
{{- define "elasticsearch.env" -}}
- name: ES_SERVER_URLS
  value: {{ include "elasticsearch.client.url" . }}
{{- if not .Values.storage.elasticsearch.anonymous }}
- name: ES_USERNAME
  value: {{ .Values.storage.elasticsearch.user }}
{{- end }}
{{- if .Values.storage.elasticsearch.usePassword }}
- name: ES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ if .Values.storage.elasticsearch.existingSecret }}{{ .Values.storage.elasticsearch.existingSecret }}{{- else }}{{ include "jaeger.fullname" . }}-elasticsearch{{- end }}
      key: {{ default "password" .Values.storage.elasticsearch.existingSecretKey }}
{{- end }}
{{- if .Values.storage.elasticsearch.tls.enabled }}
- name: ES_TLS_ENABLED
  value: "true"
- name: ES_TLS_CA
  value: {{ .Values.storage.elasticsearch.tls.ca }}
{{- end }}
{{- if .Values.storage.elasticsearch.indexPrefix }}
- name: ES_INDEX_PREFIX
  value: {{ .Values.storage.elasticsearch.indexPrefix }}
{{- end }}
{{- range $key, $value := .Values.storage.elasticsearch.env }}
- name: {{ $key | quote }}
  value: {{ $value | quote }}
{{ end -}}
{{- if .Values.storage.elasticsearch.extraEnv }}
{{ toYaml .Values.storage.elasticsearch.extraEnv }}
{{- end }}
{{- end -}}

{{/*
grpcPlugin related environment variables
*/}}
{{- define "grpcPlugin.env" -}}
{{- if .Values.storage.grpcPlugin.extraEnv }}
{{- toYaml .Values.storage.grpcPlugin.extraEnv }}
{{- end }}
{{- end -}}

{{/*
badger related environment variables
*/}}
{{- define "badger.env" -}}
- name: BADGER_EPHEMERAL
  value: {{ .Values.storage.badger.ephemeral | quote }}
{{- if not .Values.storage.badger.ephemeral }}
- name: BADGER_DIRECTORY_VALUE
  value: {{ print .Values.storage.badger.persistence.mountPath "/badger/data" | quote }}
- name: BADGER_DIRECTORY_KEY
  value: {{ print .Values.storage.badger.persistence.mountPath "/badger/key" | quote }}
{{- end }}
{{- if .Values.storage.badger.extraEnv }}
{{- toYaml .Values.storage.badger.extraEnv }}
{{- end }}
{{- end -}}

{{/*
memory related environment variables
*/}}
{{- define "memory.env" -}}
{{- if .Values.storage.memory.extraEnv }}
{{- toYaml .Values.storage.memory.extraEnv }}
{{- end }}
{{- end -}}


{{/*
Cassandra, Elasticsearch, or grpc-plugin, badger, memory related environment variables depending on which is used
*/}}
{{- define "storage.env" -}}
{{- if eq .Values.storage.type "cassandra" -}}
{{ include "cassandra.env" . }}
{{- else if eq .Values.storage.type "elasticsearch" -}}
{{ include "elasticsearch.env" . }}
{{- else if eq .Values.storage.type "grpc-plugin" -}}
{{ include "grpcPlugin.env" . }}
{{- else if eq .Values.storage.type "badger" -}}
{{ include "badger.env" . }}
{{- else if eq .Values.storage.type "memory" -}}
{{ include "memory.env" . }}
{{- end -}}
{{- end -}}

{{/*
Cassandra related command line options
*/}}
{{- define "cassandra.cmdArgs" -}}
{{- range $key, $value := .Values.storage.cassandra.cmdlineParams -}}
{{- if $value }}
- --{{ $key }}={{ $value }}
{{- else }}
- --{{ $key }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Elasticsearch related command line options
*/}}
{{- define "elasticsearch.cmdArgs" -}}
{{- range $key, $value := .Values.storage.elasticsearch.cmdlineParams -}}
{{- if $value }}
- --{{ $key }}={{ $value }}
{{- else }}
- --{{ $key }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Cassandra or Elasticsearch related command line options depending on which is used
*/}}
{{- define "storage.cmdArgs" -}}
{{- if eq .Values.storage.type "cassandra" -}}
{{- include "cassandra.cmdArgs" . -}}
{{- else if eq .Values.storage.type "elasticsearch" -}}
{{- include "elasticsearch.cmdArgs" . -}}
{{- end -}}
{{- end -}}

{{/*
Add extra argument to the command line options
Usage:
    {{ include "extra.cmdArgs" ( dict "cmdlineParams" .Values.collector.cmdlineParams ) | nindent 10  }}
*/}}
{{- define "extra.cmdArgs" -}}
{{- range $key, $value := .cmdlineParams -}}
{{- if $value }}
- --{{ $key }}={{ $value }}
{{- else }}
- --{{ $key }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Provides a basic ingress network policy
*/}}
{{- define "jaeger.ingress.networkPolicy" -}}
apiVersion: {{ include "common.capabilities.networkPolicy.apiVersion" . }}
kind: NetworkPolicy
metadata:
  name: {{ printf "%s-ingress" .Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/component: {{ .Component }}
    {{- include "jaeger.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: {{ .Component }}
  policyTypes:
  - Ingress
  ingress:
  {{- if or .ComponentValues.networkPolicy.ingressRules.namespaceSelector .ComponentValues.networkPolicy.ingressRules.podSelector }}
  - from:
    {{- if .ComponentValues.networkPolicy.ingressRules.namespaceSelector }}
    - namespaceSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.ingressRules.namespaceSelector "context" $) | nindent 10 }}
    {{- end }}
    {{- if .ComponentValues.networkPolicy.ingressRules.podSelector }}
    - podSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.ingressRules.podSelector "context" $) | nindent 10 }}
    {{- end }}
  {{- end }}
  {{- if .ComponentValues.networkPolicy.ingressRules.customRules }}
  {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.ingressRules.customRules "context" $) | nindent 2 }}
  {{- end }}
{{- end -}}

{{/*
Provides a basic egress network policy
*/}}
{{- define "jaeger.egress.networkPolicy" -}}
apiVersion: {{ include "common.capabilities.networkPolicy.apiVersion" . }}
kind: NetworkPolicy
metadata:
  name: {{ printf "%s-egress" .Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    app.kubernetes.io/component: {{ .Component }}
    {{- include "jaeger.labels" . | nindent 4 }}
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: {{ .Component }}
  policyTypes:
  - Egress
  egress:
  {{- if or .ComponentValues.networkPolicy.egressRules.namespaceSelector .ComponentValues.networkPolicy.egressRules.podSelector }}
  - to:
    {{- if .ComponentValues.networkPolicy.egressRules.namespaceSelector }}
    - namespaceSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.egressRules.namespaceSelector "context" $) | nindent 10 }}
    {{- end }}
    {{- if .ComponentValues.networkPolicy.egressRules.podSelector }}
    - podSelector:
        matchLabels: {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.egressRules.podSelector "context" $) | nindent 10 }}
    {{- end }}
  {{- end }}
  {{- if .ComponentValues.networkPolicy.egressRules.customRules }}
  {{- include "common.tplvalues.render" (dict "value" .ComponentValues.networkPolicy.egressRules.customRules "context" $) | nindent 2 }}
  {{- end }}
{{- end -}}

{{/*
Create image name value
If not tag is provided, it defaults to .Chart.AppVersion.
( dict "imageRoot" .Values.path.to.image "context" $ )
*/}}
{{- define "renderImage" -}}
{{- $image := merge .imageRoot (dict "tag" .context.Chart.AppVersion) -}}
{{- include "common.images.image" (dict "imageRoot" $image "global" .context.Values.global) -}}
{{- end -}}

{{/*
Create image name for all-in-one image
*/}}
{{- define "allInOne.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.allInOne.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for all-in-one image
*/}}
{{- define "allInOne.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.allInOne.image) "context" $) -}}
{{- end }}

{{/*
Create image name for schema image
*/}}
{{- define "schema.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.schema.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for schema image
*/}}
{{- define "schema.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.schema.image) "context" $) -}}
{{- end }}

{{/*
Create image name for ingester image
*/}}
{{- define "ingester.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.ingester.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for ingester image
*/}}
{{- define "ingester.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.ingester.image) "context" $) -}}
{{- end }}

{{/*
Create image name for agent image
*/}}
{{- define "agent.image" -}}
{{- $image := merge .Values.agent.image (dict "tag" .Chart.Annotations.Jaegerv1Version) -}}
{{- include "renderImage" ( dict "imageRoot" $image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for agent image
*/}}
{{- define "agent.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.agent.image) "context" $) -}}
{{- end }}


{{/*
Create image name for collector image
*/}}
{{- define "collector.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.collector.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for collector image
*/}}
{{- define "collector.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.collector.image) "context" $) -}}
{{- end }}

{{/*
Create image name for query image
*/}}
{{- define "query.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.query.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for query image
*/}}
{{- define "query.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.query.image .Values.query.oAuthSidecar.image) "context" $) -}}
{{- end }}

{{/*
Create image name for oAuthSidecar image
*/}}
{{- define "oAuthSidecar.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.query.oAuthSidecar.image "global" .Values.global) -}}
{{- end -}}

{{/*
Create image name for spark image
*/}}
{{- define "spark.image" -}}
{{- include "common.images.image" (dict "imageRoot" .Values.spark.image "global" .Values.global) -}}
{{- end -}}

{{/*
Create pull secrets for spark image
*/}}
{{- define "spark.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.spark.image) "context" $) -}}
{{- end }}

{{/*
Create image name for esIndexCleaner image
*/}}
{{- define "esIndexCleaner.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.esIndexCleaner.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for esIndexCleaner image
*/}}
{{- define "esIndexCleaner.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.esIndexCleaner.image) "context" $) -}}
{{- end }}

{{/*
Create image name for esRollover image
*/}}
{{- define "esRollover.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.esRollover.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for esRollover image
*/}}
{{- define "esRollover.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.esRollover.image) "context" $) -}}
{{- end }}

{{/*
Create image name for esLookback image
*/}}
{{- define "esLookback.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.esLookback.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for esLookback image
*/}}
{{- define "esLookback.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.esLookback.image) "context" $) -}}
{{- end }}

{{/*
Create image name for hotrod image
*/}}
{{- define "hotrod.image" -}}
{{- include "renderImage" ( dict "imageRoot" .Values.hotrod.image "context" $ ) -}}
{{- end -}}

{{/*
Create pull secrets for hotrod image
*/}}
{{- define "hotrod.imagePullSecrets" -}}
{{- include "common.images.renderPullSecrets" (dict "images" (list .Values.hotrod.image) "context" $) -}}
{{- end }}


{{- define "jaeger.extensionsConfig" -}}
{{- if .Values.extensions }}
{{ toYaml .Values.extensions | nindent 6 }}
{{- else }}
{{ toYaml .Values.config.extensions | nindent 6 }}
{{- end }}
{{- end }}

{{- define "jaeger.receiversConfig" -}}
{{- if .Values.receivers }}
{{ toYaml .Values.receivers | nindent 6 }}
{{- else }}
{{ toYaml .Values.config.receivers | nindent 6 }}
{{- end }}
{{- end }}

{{- define "jaeger.processorsConfig" -}}
{{- if .Values.processors }}
{{ toYaml .Values.processors | nindent 6 }}
{{- else }}
{{ toYaml .Values.config.processors | nindent 6 }}
{{- end }}
{{- end }}

{{- define "jaeger.exportersConfig" -}}
{{- if .Values.exporters }}
{{ toYaml .Values.exporters | nindent 6 }}
{{- else }}
{{ toYaml .Values.config.exporters | nindent 6 }}
{{- end }}
{{- end }}



{{- define "jaeger.serviceExtensions" -}}
{{- if and .Values.service .Values.service.extensions -}}
[{{ join ", " .Values.service.extensions }}]
{{- else -}}
[{{ join ", " .Values.config.service.extensions }}]
{{- end -}}
{{- end }}

{{- define "jaeger.serviceReceivers" -}}
{{- if and .Values.service .Values.service.pipelines .Values.service.pipelines.traces .Values.service.pipelines.traces.receivers -}}
[{{ join ", " .Values.service.pipelines.traces.receivers }}]
{{- else -}}
[{{ join ", " .Values.config.service.pipelines.traces.receivers }}]
{{- end -}}
{{- end }}

{{- define "jaeger.serviceProcessors" -}}
{{- if and .Values.service .Values.service.pipelines .Values.service.pipelines.traces .Values.service.pipelines.traces.processors -}}
[{{ join ", " .Values.service.pipelines.traces.processors }}]
{{- else -}}
[{{ join ", " .Values.config.service.pipelines.traces.processors }}]
{{- end -}}
{{- end }}

{{- define "jaeger.serviceExporters" -}}
{{- if and .Values.service .Values.service.pipelines .Values.service.pipelines.traces .Values.service.pipelines.traces.exporters -}}
[{{ join ", " .Values.service.pipelines.traces.exporters }}]
{{- else -}}
[{{ join ", " .Values.config.service.pipelines.traces.exporters }}]
{{- end -}}
{{- end }}

{{- define "jaeger.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}
