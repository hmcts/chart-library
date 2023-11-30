---
{{/*
Setup topologySpreadConstraints
*/}}
{{- define "hmcts.topologySpreadConstraints.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if and $languageValues.topologySpreadConstraints $languageValues.global.topologySpreadConstraints.enabled }}
topologySpreadConstraints:
  - maxSkew: {{ $languageValues.topologySpreadConstraints.maxSkew }}
    topologyKey: {{ $languageValues.topologySpreadConstraints.topologyKey }}
    whenUnsatisfiable: DoNotSchedule
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
    {{- if $languageValues.topologySpreadConstraints.minDomains }}
    minDomains: {{ $languageValues.topologySpreadConstraints.minDomains }}
    {{- end }}
{{- end }}
{{- end }}