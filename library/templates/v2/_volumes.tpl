{{/*
*/}}
{{- define "hmcts.volumes.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.volumes }}
{{- range $volume := $languageValues.volumes }}
  - name: {{ .name }}
{{- if has $volumes "configMap" }}
    configMap:
      name: {{ $volume.configMap.name }}
      defaultMode: {{ $volume.configMap.defaultMode }}
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