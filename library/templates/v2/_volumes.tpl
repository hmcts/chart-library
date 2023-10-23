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
{{- if hasKey $volume "configMap" }}
    configMap:
{{- range $key, $value := $volume.configMap }}
      {{ $key }}: {{ $value }}
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