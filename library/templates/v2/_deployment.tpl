{{- define "hmcts.deployment.v3.tpl" -}}
apiVersion: apps/v1
kind: Deployment
{{ template "hmcts.metadata.v2" . }}
{{- $languageValues := deepCopy .Values }}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) }}
{{- end }}
spec:
  revisionHistoryLimit: 0
  replicas: {{ $languageValues.replicas }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
{{ include "hmcts.podtemplate.v3.tpl" . | indent 2 -}}
{{- end -}}

{{- define "hmcts.deployment.v3" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.deployment.v3.tpl") -}}
{{- end -}}