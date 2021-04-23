---
{{/*
Setup inter pod anti affinity
*/}}
{{- define "hmcts.interpodantiaffinity.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.useInterpodAntiAffinity }}
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
              - {{ template "hmcts.releasename.v2" . }}
        topologyKey: "kubernetes.io/hostname"
{{- end }}
{{- end }}