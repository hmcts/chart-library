{{/*
*/}}
{{- define "hmcts.volumes.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.volumes }}
volumes:
{{- range $languageValues.volumes }}
  - name: {{ .name }}
    configMap:
      name: {{ .configMap.name }}
      defaultMode: {{ .configMap.defaultMode }}
{{- end }}
{{- if $languageValues.volumeMounts }}
volumeMounts:
{{- range $languageValues.volumeMounts }}
  - name: {{ .name }}
    mountPath: {{ .mountPath }}
{{- end }}
{{- end }}
{{- end }}