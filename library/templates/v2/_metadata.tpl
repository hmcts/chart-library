---
{{/*
All the common labels needed for the labels sections of the definitions.
*/}}
{{ define "hmcts.metadata.v2.2.3" -}}
metadata:
  name: {{ template "hmcts.releasename.v2.2.3" . }}
{{- include "hmcts.labels.v2.2.3" . | indent 2 -}}
{{- include "hmcts.annotations.v2.2.3" . | indent 2 -}}
{{- end -}}
---