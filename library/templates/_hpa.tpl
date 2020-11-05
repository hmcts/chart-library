{{- define "hmcts.hpa.v1.tpl" -}}
{{- if .Values.autoscaling.enabled }}
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
{{ template "hmcts.metadata.v1" . }}
spec:
  maxReplicas: {{ .Values.autoscaling.maxReplicas }} 
  minReplicas: {{ .Values.replicas }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "hmcts.releasename.v1" . }}
  targetCPUUtilizationPercentage: 80
{{- end }}
{{- end }}