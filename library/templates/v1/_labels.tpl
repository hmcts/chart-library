---
{{- /*
All the common labels needed for the labels sections of the definitions.
*/ -}}
{{- define "hmcts.labels.v1" }}
labels:
  app.kubernetes.io/name: {{ template "hmcts.releasename.v1" . }}
  helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
  app.kubernetes.io/managed-by: {{ .Release.Service }}
  app.kubernetes.io/instance: {{ template "hmcts.releasename.v1" . }}
  {{- if .Values.aadIdentityName }}
  aadpodidbinding: {{ .Values.aadIdentityName }}
  {{- end }}
{{- end}}
----