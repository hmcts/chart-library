{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "hmcts.annotations.v1" }}
annotations:
{{- if .Values.prometheus.enabled }}
  prometheus.io/scrape: "true"
  prometheus.io/path: {{ .Values.prometheus.path | quote }}
  prometheus.io/port: {{ .Values.applicationPort | quote }}
  {{- end }}
  {{- if .Values.buildID }}
  buildID: {{ .Values.buildID }}
  {{- end }}
{{- end -}}