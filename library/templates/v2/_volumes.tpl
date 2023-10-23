{{/*
*/}}
{{- define "hmcts.volumes.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.volumes }}
{{- range $name, $info := $languageValues.volumes }}
  - name: {{ $name }}
    configMap:
      name: {{ $name }}
      defaultMode: {{ $info.defaultMode }}
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
{{- range $name, $info := $languageValues.volumeMounts }}
  - name: {{ .name }}
    mountPath: {{ .mountPath }}
{{- end }}
{{- end }}
{{- end }}