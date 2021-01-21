---
{{/*
All the common labels needed for the labels sections of the definitions.
*/}}
{{ define "hmcts.metadata.v1" -}}
metadata:
  name: {{ template "hmcts.releasename.v1" . }}
{{- include "hmcts.labels.v1" . | indent 2 -}}
{{- include "hmcts.annotations.v1" . | indent 2 -}}
{{- end -}}
---