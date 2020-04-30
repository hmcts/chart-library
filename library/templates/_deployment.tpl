{{- define "hmcts.deployment.v1.tpl" -}}
apiVersion: apps/v1
kind: Deployment
{{ template "hmcts.metadata.v1" . }}
spec:
  revisionHistoryLimit: 0
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v1" . }}
  template:
    metadata:
      {{- (include "hmcts.labels.v1" .) | indent 6 }}
      {{- (include "hmcts.annotations.v1" .) | indent 6 }}
    spec:
      {{- ( include "hmcts.interpodantiaffinity.v1" . ) | indent 6 }}
      {{- if (not .Values.disableSecurityContext) }}
      securityContext:
        runAsUser: 1000
        fsGroup: 1000
      {{- end -}}
      {{- ( include "hmcts.secretVolumes.v1" . ) | indent 6 }}
      {{- ( include "hmcts.dnsConfig.v1" . ) | indent 6 }}
      containers:
{{ include "hmcts.container.v1.tpl" . | indent 8 -}}
{{- end -}}

{{- define "hmcts.deployment.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.deployment.v1.tpl") -}}
{{- end -}}