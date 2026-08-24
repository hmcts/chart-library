{{- define "hmcts.deployment.v7.tpl" -}}
apiVersion: apps/v1
kind: Deployment
{{ template "hmcts.metadata.v3" . }}
{{- $languageValues := deepCopy .Values }}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) }}
{{- end }}
spec:
  revisionHistoryLimit: 0
  {{- if not (($languageValues.autoscaling | default dict).enabled) }}
  replicas: {{ $languageValues.replicas | default 1 }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v3" . }}
{{ include "hmcts.podtemplate.v8.tpl" . | indent 2 -}}
{{- end -}}

{{- define "hmcts.deployment.v7" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.deployment.v7.tpl") -}}
{{- end -}}