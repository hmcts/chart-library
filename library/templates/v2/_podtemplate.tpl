{{/*
Create pod template spec.
*/}}
{{- define "hmcts.podtemplate.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
template:
  metadata:
    {{- (include "hmcts.labels.v2" .) | indent 4 }}
    {{- (include "hmcts.annotations.v2" .) | indent 4 }}
  spec:
    {{- if $languageValues.saEnabled }}
    serviceAccountName: {{ template "hmcts.releasename.v2" . }}
    {{- end }}
    {{- include "hmcts.interpodantiaffinity.v2" . | indent 4 }}
    {{- if not $languageValues.runAsRoot }}
    securityContext:
      runAsUser: 1000
      fsGroup: 1000
    {{- end }}
    {{- ( include "hmcts.secretCSIVolumes.v2" . ) | indent 4 }}
    {{- ( include "hmcts.dnsConfig.v2" . ) | indent 4 }}
    restartPolicy: {{ .Values.restartPolicy | default "Always" | quote }}
    containers:
{{ include "hmcts.container.v2.tpl" . | indent 6 -}}

{{- end -}}
