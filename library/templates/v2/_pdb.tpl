{{- define "hmcts.pdb.v2.2.2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{ if $languageValues.pdb.enabled }}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name:  {{ template "hmcts.releasename.v2.2.2" . }}-pdb
  {{- ( include "hmcts.labels.v2.2.2" . ) | indent 2 }}
spec:
  {{ if $languageValues.pdb.minAvailable }}
  minAvailable: {{ $languageValues.pdb.minAvailable }}
  {{- else -}}
  maxUnavailable: {{ $languageValues.pdb.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v2.2.2" . }}
{{- end }}
{{- end }}

{{- define "hmcts.pdb.v2.2.2" -}}
{{- template "hmcts.util.merge.v2.2.2" (append . "hmcts.pdb.v2.2.2.tpl") -}}
{{- end -}}