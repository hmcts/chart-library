---
{{/*
Setup pod affinity rules
*/}}
{{- define "hmcts.affinity.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if or ($languageValues.useInterpodAntiAffinity) ($languageValues.topologySpreadConstraints.enabled) ($languageValues.affinity) }}
affinity:
{{- if $languageValues.useInterpodAntiAffinity }}
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
              - {{ template "hmcts.releasename.v2" . }}
        topologyKey: "kubernetes.io/hostname"
{{- end -}}
{{- if $languageValues.topologySpreadConstraints.enabled }}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.azure.com/scalesetpriority
              operator: In
              values:
                - spot
            - key: kubernetes.azure.com/scalesetpriority
              operator: DoesNotExist
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
{{ if $languageValues.affinity }}
{{ toYaml $languageValues.affinity| indent 2 }}
{{- end -}}
{{- end }}
{{- end }}
