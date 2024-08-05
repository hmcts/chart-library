{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "hmcts.dnsConfig.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- with $languageValues }}
{{- if and .dnsConfig .dnsConfig.ndots }}
dnsConfig:
  options:
    - name: ndots
      value: {{ .dnsConfig.ndots | quote }}
    {{- if .dnsConfig.singleRequestTcp }}
    - name: single-request-reopen
    - name: use-vc
    {{- end }} 
{{- end }}  
{{- end }}
{{- end -}}