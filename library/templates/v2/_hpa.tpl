{{- define "hmcts.hpa.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.autoscaling }}
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
{{ template "hmcts.metadata.v2" . }}
spec:
  maxReplicas: {{ $languageValues.autoscaling.maxReplicas }}
  minReplicas: {{ $languageValues.replicas }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "hmcts.releasename.v2" . }}
  {{- if $languageValues.autoscaling.targetCPUUtilizationPercentage }}
  targetCPUUtilizationPercentage: {{ $languageValues.autoscaling.targetCPUUtilizationPercentage }}
  {{- else }}
  targetCPUUtilizationPercentage: 80
  {{- end }}
{{- end }}
{{- end }}