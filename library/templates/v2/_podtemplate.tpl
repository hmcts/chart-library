{{/*
Create pod template spec.
*/}}
{{- define "hmcts.podtemplate.v8.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
template:
  metadata:
    {{- (include "hmcts.labels.v3" .) | indent 4 }}
    {{- if $languageValues.useWorkloadIdentity }}
      azure.workload.identity/use: "true"
    {{- end }}
    {{- (include "hmcts.annotations.v3" .) | indent 4 }}
  spec:
    
    {{- if $languageValues.saEnabled}}
    serviceAccountName: {{ .Release.Namespace }}
    {{ else if and (not $languageValues.saEnabled) ($languageValues.customServiceAccountName)  }}
    serviceAccountName: {{ $languageValues.customServiceAccountName }}
    {{- end }}

    {{- include "hmcts.affinity.v2" . | indent 4 }}
    {{- if not $languageValues.runAsRoot }}
    securityContext:
      runAsUser: 1000
      fsGroup: 1000
    {{- end }}
    {{- if $languageValues.nodeSelector }}
    nodeSelector:
  {{ toYaml $languageValues.nodeSelector | indent 4 }}
    {{- end }}
    {{- ( include "hmcts.tolerations.v4" . ) | indent 4 }}
    {{- ( include "hmcts.topologySpreadConstraints.v2" . ) | indent 4 }}
    {{- ( include "hmcts.dnsConfig.v2" . ) | indent 4 }}
    {{- $vols := trim (printf "%s%s" (include "hmcts.volumes.v3" .) (include "hmcts.secretCSIVolumes.v4" .)) }}
    {{- if $vols }}
    volumes:
    {{- ( include "hmcts.volumes.v3" . ) | indent 4 }}
    {{- ( include "hmcts.secretCSIVolumes.v4" . ) | indent 4 }}
    {{- end }}
    restartPolicy: {{ $languageValues.restartPolicy | default "Always" | quote }}
    terminationGracePeriodSeconds: {{ $languageValues.terminationGracePeriodSeconds | default 30 }}
    containers:
{{ include "hmcts.container.v5.tpl" . | indent 6 -}}

{{- end -}}
