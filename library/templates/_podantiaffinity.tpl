---
{{/*
Setup inter pod anti affinity
*/}}
{{- define "hmcts.interpodantiaffinity.v1" }}
{{- if .Values.useInterpodAntiAffinity }}
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
              - {{ template "hmcts.releasename.v1" . }}
        topologyKey: "kubernetes.io/hostname"
{{- end }}
{{- end }}