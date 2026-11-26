{{- define "hmcts.deployment.v8.tpl" -}}
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
  replicas: {{ ternary 1 $languageValues.replicas (eq $languageValues.replicas nil) }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v3" . }}
{{ include "hmcts.podtemplate.v8.tpl" . | indent 2 -}}
{{- end -}}

{{- define "hmcts.deployment.v8" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.deployment.v8.tpl") -}}
{{- end -}}