{{/*
Additional Path based routes
*/}}
{{- define "hmcts.additionalPathBasedRoutes" }}
{{- range $path, $serviceName := .Values.additionalPathBasedRoutes }}
  - path: {{ $path }}
    backend:
      serviceName: {{ tpl $serviceName $ }}
      servicePort: 80
{{- end }}
{{- end -}}