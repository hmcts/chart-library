{{- define "hmcts.sa.v1.tpl" -}}
{{ if .Values.saEnabled }}
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