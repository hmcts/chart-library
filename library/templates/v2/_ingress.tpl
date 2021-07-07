{{- define "hmcts.ingress.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{ if or ($languageValues.ingressHost ) ($languageValues.registerAdditionalDns.enabled) }}
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
  {{- ( include "hmcts.labels.v2" . ) | indent 2 }}
  annotations:
    kubernetes.io/ingress.class: {{ $languageValues.ingressClass }}
    {{- if $languageValues.tls }}
    traefik.ingress.kubernetes.io/router.tls: "true"
spec:
  rules:
  {{- if $languageValues.ingressHost }}
  - host: {{ tpl $languageValues.ingressHost $ | lower }}
    http:
      paths:
      {{- ( include "hmcts.additionalPathBasedRoutes.v2" .) | indent 4 }}
      - path: /
        backend:
          serviceName: {{ template "hmcts.releasename.v2" . }}
          servicePort: 80
  {{- end }}
  {{- if $languageValues.registerAdditionalDns.enabled }}
  - host: {{ $languageValues.registerAdditionalDns.prefix }}-{{ tpl $languageValues.registerAdditionalDns.primaryIngressHost $ }}
    http:
      paths:
      {{- ( include "hmcts.additionalPathBasedRoutes.v2" .) | indent 4 }}
      - path: /
        backend:
          serviceName: {{ template "hmcts.releasename.v2" . }}
          servicePort: 80
  {{- end }}
{{- end}}
{{- end }}

{{- define "hmcts.ingress.v2" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.ingress.v2.tpl") -}}
{{- end -}}

{{/*
Additional Path based routes
*/}}
{{- define "hmcts.additionalPathBasedRoutes.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- range $path, $serviceName := $languageValues.additionalPathBasedRoutes }}
  - path: {{ $path }}
    backend:
      serviceName: {{ tpl $serviceName $ | lower }}
      servicePort: 80
{{- end }}
{{- end -}}
