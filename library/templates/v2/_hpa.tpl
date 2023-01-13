{{- define "hmcts.hpa.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
{{ template "hmcts.metadata.v2" . }}
spec:
  maxReplicas: {{ $languageValues.autoscaling.maxReplicas }}
  minReplicas: {{ $languageValues.replicas }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "hmcts.releasename.v2" . }}
    metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        {{- if $languageValues.autoscaling.targetCPUUtilizationPercentage }}
        averageUtilization: {{ $languageValues.autoscaling.targetCPUUtilizationPercentage }}
        {{- else }}
        averageUtilization: 80
        {{- end }}
{{- end }}
{{- end }}