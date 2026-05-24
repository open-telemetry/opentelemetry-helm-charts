{{- define "helper.pod" -}}
serviceAccountName: {{ template "helper.managerServiceAccountName" . }}
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
  - name: manager
    image: {{ template "helper.dockerImageName" . }}
    command:
      - /manager
      - --config-file
      - /conf/manager.yaml
    ports:
      - containerPort: 9443
        name: webhook-server
        protocol: TCP
      {{- if .Values.manager.pprofPort }}
      - containerPort: {{ .Values.manager.pprofPort }}
        name: pprof
        protocol: TCP
      {{- end }}
    volumeMounts:
      {{- if or .Values.configMap.create .Values.configMap.existingName }}
      - name: config-volume
        mountPath: /conf/
      {{- end }}
      - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
        name: serviceaccount-token
        readOnly: true
      - mountPath: /tmp/k8s-webhook-server/serving-certs
        name: cert
        readOnly: true
      {{- if .Values.extraVolumeMounts }}
      {{- toYaml .Values.extraVolumeMounts | nindent 6 }}
      {{- end }}
    env:
      {{- with .Values.manager.extraEnvs }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    {{- with .Values.manager.livenessProbe }}
    livenessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.manager.readinessProbe }}
    readinessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.manager.resources }}
    resources:
      {{- toYaml . | nindent 6 }}
    {{- end }}
volumes:
  {{- if or .Values.configMap.create .Values.configMap.existingName }}
  - name: config-volume
    configMap:
      name: {{ include "helper.managerConfigMapName" . }}
      {{- $key := "manager.yaml" -}}
      {{- if and .Values.configMap.existingName .Values.configMap.existingKey -}}
        {{- $key = .Values.configMap.existingKey -}}
      {{- end }}
      items:
        - key: {{ $key }}
          path: manager.yaml
  {{- end }}
  - name: cert
    secret:
      defaultMode: 420
      secretName: {{ .Values.cert.secretName }}
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
  {{- if .Values.extraVolumes }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
  {{- end }}
  {{- end }}
