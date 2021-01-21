{{- define "hmcts.configmap.v1.tpl" -}}
{{- if .Values.configmap }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "hmcts.releasename.v1" . }}
  {{- ( include "hmcts.labels.v1" . ) | indent 2 }}
data:
  {{- range $key, $val := .Values.configmap }}
  {{ $key }}: {{ $val | quote }}
  {{- end}}
{{- end}}
{{- end -}}

{{- define "hmcts.configmap.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.configmap.v1.tpl") -}}
{{- end -}}