{{- define "hmcts.hpa.v1.tpl" -}}
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
{{ template "hmcts.metadata.v1" . }}
spec:
  maxReplicas: {{ .Values.autoscaling.maxReplicas }} 
  {{ if .Values.autoscaling.minReplicas }}
  minReplicas: {{ .Values.autoscaling.minReplicas }}
  {{ else }}
  minReplicas: 2
  {{ end }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "hmcts.releasename.v1" . }}
    metrics:
      - type: Resource
        resource:
          name: cpu
          targetAverageUtilization: 80
      - type: Resource
        resource:
          name: cpu
          targetAverageUtilization: 80
{{- end }}
{{- end }}