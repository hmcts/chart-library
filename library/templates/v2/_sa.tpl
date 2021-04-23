{{- define "hmcts.sa.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{ if $languageValues.saEnabled }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
  {{- ( include "hmcts.labels.v2" . ) | indent 2 }}
{{- end -}}
{{- end -}}

{{- define "hmcts.sa.v2" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.sa.v2.tpl") -}}
{{- end -}}