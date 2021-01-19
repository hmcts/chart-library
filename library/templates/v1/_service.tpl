{{- define "hmcts.service.v1.tpl" -}}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ template "hmcts.releasename.v1" . }}
  {{- ( include "hmcts.labels.v1" . ) | indent 2 }}
  {{- /*
  # WARNING: ingressSessionAffinity is a temporary option.
  # This is subject to removal without notice. Do NOT use for any reason!
  */ -}}
  {{- if hasKey .Values "ingressSessionAffinity" }}
  {{- if and .Values.ingressSessionAffinity .Values.ingressSessionAffinity.enabled }}
  annotations:
    traefik.ingress.kubernetes.io/affinity: "true"
    traefik.ingress.kubernetes.io/session-cookie-name: {{ .Values.ingressSessionAffinity.sessionCookieName | quote }}
  {{- end }}
  {{- end }}
spec:
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: {{ .Values.applicationPort }}
  selector:
    app.kubernetes.io/name: {{ template "hmcts.releasename.v1" . }}
{{- end }}

{{- define "hmcts.service.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.service.v1.tpl") -}}
{{- end -}}