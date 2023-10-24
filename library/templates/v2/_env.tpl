{{/*
*/}}
{{- define "hmcts.env.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.env }}
{{- range $languageValues.env }}
  - name: {{ .name }}
    {{- if .secretKeyRef }}
    valueFrom:
      secretKeyRef:
        name: {{ .secretKeyRef.name }}
        key: {{ .secretKeyRef.key }}
    {{- else }}
    value: {{ .value }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}