{{- define "hmcts.sa.v1.tpl" -}}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{ if $languageValues.saEnabled }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ template "hmcts.releasename.v1" . }}
  {{- ( include "hmcts.labels.v1" . ) | indent 2 }}
{{- end -}}
{{- end -}}

{{- define "hmcts.sa.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.sa.v1.tpl") -}}
{{- end -}}