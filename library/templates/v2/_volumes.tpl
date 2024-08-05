{{/*
*/}}
{{- define "hmcts.volumes.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.volumes }}
{{- range $languageValues.volumes }}
  - name: {{ .name }}
{{- if .configMap }}
    configMap:
      name: {{ .configMap.name }}
      defaultMode: {{ .configMap.defaultMode }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
*/}}
{{- define "hmcts.volumeMounts.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.volumeMounts }}
{{- range $languageValues.volumeMounts }}
  - name: {{ .name }}
    mountPath: {{ .mountPath }}
{{- end }}
{{- end }}
{{- end }}