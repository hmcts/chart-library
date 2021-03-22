---
{{- /*
All the common labels needed for the labels sections of the definitions.
*/ -}}
{{- define "hmcts.labels.v2" }}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) }}
labels:
  app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
  helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  app.kubernetes.io/instance: {{ template "hmcts.releasename.v2" . }}
  {{- if $languageValues.aadIdentityName }}
  aadpodidbinding: {{ $languageValues.aadIdentityName }}
  {{- end }}
  {{- if $languageValues.labels }}
  {{- range $key, $val := $languageValues.labels }}
  {{ $key }}: {{ $val }}
  {{- end}}
  {{- end}}
{{- end}}
----