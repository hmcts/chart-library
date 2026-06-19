{{/*
Create job template spec.
*/}}
{{- define "hmcts.jobtemplate.v1.tpl" -}}
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
  spec:
    
    {{- if $languageValues.saEnabled}}
    serviceAccountName: {{ .Release.Namespace }}
    {{ else if and (not $languageValues.saEnabled) ($languageValues.customServiceAccountName)  }}
    serviceAccountName: {{ $languageValues.customServiceAccountName }}
    {{- end }}

    {{- include "hmcts.affinity.v1" . | indent 4 }}
    {{- if not $languageValues.runAsRoot }}
    securityContext:
      runAsUser: 1000
      fsGroup: 1000
    {{- end }}
    {{- if $languageValues.nodeSelector }}
    nodeSelector:
  {{ toYaml $languageValues.nodeSelector | indent 4 }}
    {{- end }}
    {{- ( include "hmcts.tolerations.v3" . ) | indent 4 }}
    {{- ( include "hmcts.topologySpreadConstraints.v1" . ) | indent 4 }}
    {{- ( include "hmcts.dnsConfig.v2" . ) | indent 4 }}
    restartPolicy: {{ $languageValues.restartPolicy | default "Always" | quote }}
    terminationGracePeriodSeconds: {{ $languageValues.terminationGracePeriodSeconds | default 30 }}
    containers:
{{ include "hmcts.jobcontainer.v1.tpl" . | indent 6 -}}

{{- end -}}
