{{/*
*/}}
{{- define "hmcts.tolerations.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.tolerations }}
tolerations:
{{- range $languageValues.tolerations }}
  - key: {{ .key }}
    effect: {{ .effect }}
    operator: {{ .operator }}
    value: {{ .value }}
{{- end }}
{{- end }}
{{- end }}