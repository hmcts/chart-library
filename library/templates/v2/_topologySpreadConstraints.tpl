---
{{/*
Setup topologySpreadConstraints
*/}}
{{- define "hmcts.topologySpreadConstraints.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if and $languageValues.spotInstances.enabled }}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: role
    whenUnsatisfiable: DoNotSchedule
    nodeAffinityPolicy: Honor
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
    matchLabelKeys:
      - pod-template-hash
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: ScheduleAnyway
    nodeAffinityPolicy: Honor
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
    matchLabelKeys:
      - pod-template-hash
{{- end }}
{{- end }}