{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "hmcts.annotations.v2" }}
{{- $languageValues := deepCopy .Values}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) )}}
{{- end -}}
{{- with $languageValues }}
annotations:
  {{- $applicationPort := .applicationPort -}} 
  {{- with .prometheus }}
  {{- if .enabled }}
  prometheus.io/scrape: "true"
  prometheus.io/path: {{ .path | quote }}
  prometheus.io/port: {{ $applicationPort | quote }}
  {{- end }}
  {{- end }}
  {{- if .buildID }}
  buildID: {{ .buildID }}
  {{- end }}
{{- end -}}
{{- end -}}