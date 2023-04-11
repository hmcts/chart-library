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
  annotations:
    {{- if $languageValues.workloadIdentityEnabled }}
    azure.workload.identity/client-id: {{ $languageValues.workloadIdentityClientID }}
    {{- end }}
  {{- ( include "hmcts.labels.v2" . ) | indent 2 }}
  {{- if $languageValues.workloadIdentityEnabled }}
    azure.workload.identity/use: "true"
  {{- end }}
{{- end -}}
{{- end -}}

{{- define "hmcts.sa.v2" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.sa.v2.tpl") -}}
{{- end -}}