---
{{/*
Setup topologySpreadConstraints
*/}}
{{- define "hmcts.topologySpreadConstraints.v1" }}
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.azure.com/agentpool
    whenUnsatisfiable: DoNotSchedule
    nodeAffinityPolicy: Honor
    nodeTaintsPolicy: Honor
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}
    matchLabelKeys:
      - pod-template-hash
  - maxSkew: 2
    topologyKey: kubernetes.io/hostname
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