{{- define "hmcts.deployment.v1.tpl" -}}
apiVersion: apps/v1
kind: Deployment
{{ template "hmcts.metadata.v1" . }}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) }}
spec:
  revisionHistoryLimit: 0
  replicas: {{ $languageValues.replicas }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v1" . }}
{{ include "hmcts.podtemplate.v1.tpl" . | indent 2 -}}
{{- end -}}

{{- define "hmcts.deployment.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.deployment.v1.tpl") -}}
{{- end -}}