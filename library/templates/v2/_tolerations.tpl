{{/*
*/}}
{{- define "hmcts.tolerations.v3" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if or ($languageValues.tolerations) ((($languageValues.spotInstances | default dict).enabled)) }}
tolerations:
{{- if $languageValues.tolerations }}
{{- range $languageValues.tolerations }}
  - key: {{ .key }}
    effect: {{ .effect }}
    operator: {{ .operator }}
    {{- if .value }}
    value: {{ .value }}
    {{- end }}
{{- end -}}
{{- end -}}
{{- if (($languageValues.spotInstances | default dict).enabled) }}
  - key: kubernetes.azure.com/scalesetpriority
    effect: NoSchedule
    operator: Equal
    value: spot
{{- end -}}
{{- end }}
{{- end }}