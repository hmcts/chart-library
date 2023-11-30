---
{{/*
Setup topologySpreadConstraints
*/}}
{{- define "hmcts.topologySpreadConstraints.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.topologySpreadConstraints }}
topologySpreadConstraints:
  - maxSkew: {{ $languageValues.topologySpreadConstraints.maxSkew }}
    topologyKey: {{ $languageValues.topologySpreadConstraints.topologyKey }}
    whenUnsatisfiable: DoNotSchedule
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
        helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    {{- if $languageValues.topologySpreadConstraints.minDomains }}
    minDomains: {{ $languageValues.topologySpreadConstraints.minDomains }}
    {{- end }}
{{- end }}
{{- end }}