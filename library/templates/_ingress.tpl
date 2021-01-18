{{- define "hmcts.ingress.v1.tpl" -}}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) }}
{{ if or ($languageValues.ingressHost ) ($languageValues.registerAdditionalDns.enabled) }}
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: {{ template "hmcts.releasename.v1" . }}
  {{- ( include "hmcts.labels.v1" . ) | indent 2 }}
  annotations:
    kubernetes.io/ingress.class: {{ $languageValues.ingressClass }}
spec:
  rules:
  {{- if $languageValues.ingressHost }}
  - host: {{ tpl $languageValues.ingressHost $ }}
    http:
      paths:
      {{- ( include "hmcts.additionalPathBasedRoutes.v1" .) | indent 4 }}
      - path: /
        backend:
          serviceName: {{ template "hmcts.releasename.v1" . }}
          servicePort: 80
  {{- end }}
  {{- if $languageValues.registerAdditionalDns.enabled }}
  - host: {{ $languageValues.registerAdditionalDns.prefix }}-{{ tpl $languageValues.registerAdditionalDns.primaryIngressHost $ }}
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
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) }}
{{- range $path, $serviceName := $languageValues.additionalPathBasedRoutes }}
  - path: {{ $path }}
    backend:
      serviceName: {{ tpl $serviceName $ }}
      servicePort: 80
{{- end }}
{{- end -}}
