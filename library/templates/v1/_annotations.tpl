{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "hmcts.annotations.v1" }}
annotations:
  {{- $applicationPort := .Values.applicationPort -}} 
  {{- with .Values.prometheus }}
  {{- if .enabled }}
  prometheus.io/scrape: "true"
  prometheus.io/path: {{ .path | quote }}
  prometheus.io/port: {{ $applicationPort | quote }}
  {{- end }}
  {{- end }}
  {{- if .Values.buildID }}
  buildID: {{ .Values.buildID }}
  {{- end }}
{{- end -}}