{{/*
*/}}
{{- define "hmcts.tolerations.v3" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if or ($languageValues.tolerations) ($languageValues.spotInstances.enabled) }}
tolerations:
{{- if $languageValues.tolerations }}
{{- range $languageValues.tolerations }}
  - key: {{ .key }}
    effect: {{ .effect }}
    operator: {{ .operator }}
    value: {{ .value }}
{{- end -}}
{{- end -}}
{{- if $languageValues.spotInstances.enabled }}
  - key: kubernetes.azure.com/scalesetpriority
    effect: NoSchedule
    operator: Equal
    value: spot
{{- end -}}
{{- end }}
{{- end }}