{{- define "hmcts.configmap.v2.tpl" -}}
{{- if .Values.configmap }}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
  {{- ( include "hmcts.labels.v2" . ) | indent 2 }}
data:
  {{- range $key, $val := $languageValues.configmap }}
  {{ $key }}: {{ $val | quote }}
  {{- end}}
{{- end}}
{{- end -}}

{{- define "hmcts.configmap.v2" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.configmap.v2.tpl") -}}
{{- end -}}