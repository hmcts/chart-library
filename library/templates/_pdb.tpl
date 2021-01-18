{{- define "hmcts.pdb.v1.tpl" -}}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{ if $languageValues.pdb.enabled }}
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name:  {{ template "hmcts.releasename.v1" . }}
  {{- ( include "hmcts.labels.v1" . ) | indent 2 }}
spec:
  {{ if $languageValues.pdb.minAvailable }}
  minAvailable: {{ $languageValues.pdb.minAvailable }}
  {{- else -}}
  maxUnavailable: {{ $languageValues.pdb.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v1" . }}
{{- end }}
{{- end }}

{{- define "hmcts.pdb.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.pdb.v1.tpl") -}}
{{- end -}}