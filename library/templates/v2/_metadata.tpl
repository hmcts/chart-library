---
{{/*
All the common labels needed for the labels sections of the definitions.
*/}}
{{ define "hmcts.metadata.v3" -}}
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
{{- include "hmcts.labels.v3" . | indent 2 -}}
{{- include "hmcts.annotations.v2" . | indent 2 -}}
{{- end -}}
---