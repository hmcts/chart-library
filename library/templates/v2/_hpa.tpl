{{- define "hmcts.hpa.v5.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.autoscaling.enabled }}
{{- if or (not $languageValues.global.devMode) $languageValues.autoscaling.enabledForDevMode}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
{{ template "hmcts.metadata.v2" . }}
spec:
  maxReplicas: {{ $languageValues.autoscaling.maxReplicas | default (add $languageValues.replicas 2) }}
  minReplicas: {{ $languageValues.autoscaling.minReplicas | default $languageValues.replicas }}
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ template "hmcts.releasename.v2" . }}
  metrics:
  {{- if $languageValues.autoscaling.cpu.enabled }}
  {{/* type: Resource is rendered at the bottom of the resource block in the template.*/}}
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ $languageValues.autoscaling.cpu.averageUtilization }}
  {{- end }}
  {{- if $languageValues.autoscaling.memory.enabled }}
  {{/*type: Resource is rendered at the bottom of the resource block in the template.*/}}
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: {{ $languageValues.autoscaling.memory.averageUtilization }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
