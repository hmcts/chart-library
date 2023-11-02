{{/*
Create pod template spec.
*/}}
{{- define "hmcts.podtemplate.v4.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
template:
  metadata:
    {{- (include "hmcts.labels.v2" .) | indent 4 }}
    {{- if $languageValues.useWorkloadIdentity }}
      azure.workload.identity/use: "true"
    {{- end }}
    {{- (include "hmcts.annotations.v2" .) | indent 4 }}
  spec:
    {{- if and $languageValues.saEnabled (not $languageValues.saOverride.enabled) }}
    serviceAccountName: {{ .Release.Namespace }}
    {{ else if and $languageValues.saEnabled $languageValues.saOverride.enabled }}
    serviceAccountName: {{ $languageValues.saOverride.serviceAccountName }}
    {{- end }}
    {{- include "hmcts.interpodantiaffinity.v2" . | indent 4 }}
    {{- if not $languageValues.runAsRoot }}
    securityContext:
      runAsUser: 1000
      fsGroup: 1000
    {{- end }}
    {{- if $languageValues.nodeSelector }}
    nodeSelector:
  {{ toYaml $languageValues.nodeSelector | indent 4 }}
    {{- end }}
    {{- ( include "hmcts.tolerations.v2" . ) | indent 4 }}
    {{- ( include "hmcts.dnsConfig.v2" . ) | indent 4 }}
    volumes:
    {{- ( include "hmcts.volumes.v2" . ) | indent 4 }}
    {{- ( include "hmcts.secretCSIVolumes.v2" . ) | indent 4 }}
    restartPolicy: {{ $languageValues.restartPolicy | default "Always" | quote }}
    terminationGracePeriodSeconds: {{ $languageValues.terminationGracePeriodSeconds | default 30 }}
    containers:
{{ include "hmcts.container.v3.tpl" . | indent 6 -}}

{{- end -}}
