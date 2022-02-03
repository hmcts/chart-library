{{- define "hmcts.ingress.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{ if or ($languageValues.ingressHost ) ($languageValues.registerAdditionalDns) }}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
  {{- ( include "hmcts.labels.v2" . ) | indent 2 }}
  annotations:
    {{- if not $languageValues.spec.disableIngressClassAnnotation }}
    kubernetes.io/ingress.class: {{ $languageValues.ingressClass }}
    {{- end }}
    {{- if not $languageValues.disableTraefikTls }}
    traefik.ingress.kubernetes.io/router.tls: "true"
    {{- end }}
spec:
  ingressClassName: {{ $languageValues.ingressClass }}
  rules:
  {{- if $languageValues.ingressHost }}
  - host: {{ tpl $languageValues.ingressHost $ | lower }}
    http:
      paths:
      {{- ( include "hmcts.additionalPathBasedRoutes.v2" .) | indent 4 }}
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ template "hmcts.releasename.v2" . }}
            port:
              number: 80
  {{- end }}
  {{- if $languageValues.registerAdditionalDns.enabled }}
  - host: {{ $languageValues.registerAdditionalDns.prefix }}-{{ $languageValues.registerAdditionalDns }}
    http:
      paths:
      {{- ( include "hmcts.additionalPathBasedRoutes.v2" .) | indent 4 }}
      - path: /
        pathType: Prefix
        backend:
          service:
            name: {{ template "hmcts.releasename.v2" . }}
            port:
              number: 80
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
    pathType: Prefix
    backend:
      service:
        name: {{ tpl $serviceName $ | lower }}
        port:
          number: 80s
{{- end }}
{{- end -}}
