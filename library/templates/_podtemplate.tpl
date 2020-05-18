{{/*
Create pod template spec.
*/}}
{{- define "hmcts.podtemplate.v1.tpl" -}}
template:
  metadata:
    {{- (include "hmcts.labels.v1" .) | indent 4 }}
    {{- (include "hmcts.annotations.v1" .) | indent 4 }}
  spec:
    {{- include "hmcts.interpodantiaffinity.v1" . | indent 4 }}
    securityContext:
      runAsUser: 1000
      fsGroup: 1000
    {{- ( include "hmcts.secretVolumes.v1" . ) | indent 4 }}
    {{- ( include "hmcts.dnsConfig.v1" . ) | indent 4 }}
    containers:
{{ include "hmcts.container.v1.tpl" . | indent 6 -}}

{{- end -}}