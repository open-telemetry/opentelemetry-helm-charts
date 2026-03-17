{{- define "helper.pod" -}}
serviceAccountName: {{ template "helper.targetAllocatorServiceAccountName" . }}
automountServiceAccountToken: false
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
containers:
  - name: targetallocator
    image: {{ template "helper.dockerImageName" . }}
    ports:
      - containerPort: 8080
        name: http-port
    volumeMounts:
      - name: config-volume
        mountPath: /conf/
      - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
        name: serviceaccount-token
        readOnly: true
    env: # Workaround for https://github.com/open-telemetry/opentelemetry-operator/pull/3976
      - name: OTELCOL_NAMESPACE
        value: {{ .Values.targetAllocator.config.collector_namespace | default .Release.Namespace }}
    {{- with .Values.targetAllocator.livenessProbe }}
    livenessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.targetAllocator.readinessProbe }}
    readinessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.targetAllocator.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
volumes:
  - name: config-volume
    configMap:
      name: {{ template "helper.targetAllocatorConfigMapName" . }}
  - name: serviceaccount-token
    projected:
      defaultMode: 0444
      sources:
        - serviceAccountToken:
            path: token
        - configMap:
            name: kube-root-ca.crt
            items:
              - key: ca.crt
                path: ca.crt
        - downwardAPI:
            items:
              - path: namespace
                fieldRef:
                  apiVersion: v1
                  fieldPath: metadata.namespace
{{- end -}}
