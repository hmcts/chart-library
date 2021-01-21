{{- define "hmcts.ingress.v1.tpl" -}}
{{ if or (.Values.ingressHost ) (.Values.registerAdditionalDns.enabled) }}
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: {{ template "hmcts.releasename.v1" . }}
  {{- ( include "hmcts.labels.v1" . ) | indent 2 }}
  annotations:
    kubernetes.io/ingress.class: {{ .Values.ingressClass }}
spec:
  rules:
  {{- if .Values.ingressHost }}
  - host: {{ tpl .Values.ingressHost $ }}
    http:
      paths:
      {{- ( include "hmcts.additionalPathBasedRoutes.v1" .) | indent 4 }}
      - path: /
        backend:
          serviceName: {{ template "hmcts.releasename.v1" . }}
          servicePort: 80
  {{- end }}
  {{- if .Values.registerAdditionalDns.enabled }}
  - host: {{ .Values.registerAdditionalDns.prefix }}-{{ tpl .Values.registerAdditionalDns.primaryIngressHost $ }}
    http:
      paths:
      {{- ( include "hmcts.additionalPathBasedRoutes.v1" .) | indent 4 }}
      - path: /
        backend:
          serviceName: {{ template "hmcts.releasename.v1" . }}
          servicePort: 80
  {{- end }}
{{- end}}
{{- end }}

{{- define "hmcts.ingress.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.ingress.v1.tpl") -}}
{{- end -}}

{{/*
Additional Path based routes
*/}}
{{- define "hmcts.additionalPathBasedRoutes.v1" }}
{{- range $path, $serviceName := .Values.additionalPathBasedRoutes }}
  - path: {{ $path }}
    backend:
      serviceName: {{ tpl $serviceName $ }}
      servicePort: 80
{{- end }}
{{- end -}}
