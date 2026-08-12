{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "hmcts.annotations.v3" }}
{{- $languageValues := deepCopy .Values}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) )}}
{{- end -}}
{{- $prometheusEnabled := false -}}
{{- with $languageValues.prometheus }}
{{- if .enabled }}
{{- $prometheusEnabled = true -}}
{{- end }}
{{- end }}
{{- $buildIDEnabled := not (empty $languageValues.buildID) -}}
{{- if or $prometheusEnabled $buildIDEnabled }}
annotations:
  {{- $applicationPort := $languageValues.applicationPort -}}
  {{- with $languageValues.prometheus }}
  {{- if .enabled }}
  prometheus.io/scrape: "true"
  prometheus.io/path: {{ .path | quote }}
  prometheus.io/port: {{ $applicationPort | quote }}
  {{- end }}
  {{- end }}
  {{- if $languageValues.buildID }}
  buildID: {{ $languageValues.buildID }}
  {{- end }}
{{- end -}}
{{- end -}}