{{- define "hmcts.hpa.v1.tpl" -}}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- if $languageValues.autoscaling.enabled }}
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
{{ template "hmcts.metadata.v1" . }}
spec:
  maxReplicas: {{ $languageValues.autoscaling.maxReplicas }} 
  minReplicas: {{ $languageValues.replicas }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "hmcts.releasename.v1" . }}
  {{- if $languageValues.autoscaling.targetCPUUtilizationPercentage }}
  targetCPUUtilizationPercentage: {{ $languageValues.autoscaling.targetCPUUtilizationPercentage }}
  {{- else }}
  targetCPUUtilizationPercentage: 80
  {{- end }}
{{- end }}
{{- end }}