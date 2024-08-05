---
{{/*
Setup pod affinity rules
*/}}
{{- define "hmcts.affinity.v1" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{ if $languageValues.affinity }}
affinity:
{{ toYaml $languageValues.affinity | indent 2 }}
{{- else }}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.azure.com/mode
              operator: NotIn
              values:
                - system
{{- if $languageValues.spotInstances.enabled }}
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 50
        preference:
          matchExpressions:
            - key: kubernetes.azure.com/scalesetpriority
              operator: In
              values:
              - spot
      - weight: 1
        preference:
          matchExpressions:
            - key: kubernetes.azure.com/scalesetpriority
              operator: DoesNotExist
{{- end -}}
{{- end }}
{{- end }}
