{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "hmcts.dnsConfig.v1" }}
{{- if and .Values.dnsConfig .Values.dnsConfig.ndots }}
dnsConfig:
  options:
    - name: ndots
      value: {{ .Values.dnsConfig.ndots | quote }}
    {{- if .Values.dnsConfig.singleRequestTcp }}
    - name: single-request-reopen
    - name: use-vc
    {{- end }} 
{{- end }}  
{{- end -}}