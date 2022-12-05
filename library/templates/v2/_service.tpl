{{- define "hmcts.service.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ template "hmcts.releasename.v2" . }}
  {{- ( include "hmcts.labels.v2" . ) | indent 2 }}
  {{- /*
  # WARNING: ingressSessionAffinity is a temporary option.
  # This is subject to removal without notice. Do NOT use for any reason!
  */ -}}
  {{- if hasKey $languageValues "ingressSessionAffinity" }}
  {{- if and $languageValues.ingressSessionAffinity $languageValues.ingressSessionAffinity.enabled }}
  annotations:
    traefik.ingress.kubernetes.io/service.sticky.cookie: "true"
    traefik.ingress.kubernetes.io/service.sticky.cookie.name: {{ $languageValues.ingressSessionAffinity.sessionCookieName | quote }}
  {{- end }}
  {{- end }}
spec:
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: {{ $languageValues.applicationPort }}
  selector:
    app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
{{- end }}

{{- define "hmcts.service.v2" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.service.v2.tpl") -}}
{{- end -}}
