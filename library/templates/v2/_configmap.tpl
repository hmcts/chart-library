{{- define "hmcts.configmap.v3.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.configmap }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
  {{- ( include "hmcts.labels.v3" . ) | indent 2 }}
data:
  {{- range $key, $val := $languageValues.configmap }}
  {{ $key }}: {{ $val | quote }}
  {{- end}}
{{- end}}
{{- end -}}

{{- define "hmcts.configmap.v3" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.configmap.v3.tpl") -}}
{{- end -}}