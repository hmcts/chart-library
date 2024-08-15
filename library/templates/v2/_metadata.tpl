---
{{/*
All the common labels needed for the labels sections of the definitions.
*/}}
{{ define "hmcts.metadata.v2" -}}
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
{{- include "hmcts.labels.v2" . | indent 2 -}}
{{- include "hmcts.annotations.v2" . | indent 2 -}}
{{- end -}}
---