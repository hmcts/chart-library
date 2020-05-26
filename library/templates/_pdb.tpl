{{- define "hmcts.pdb.v1.tpl" -}}
{{ if .Values.pdb.enabled }}
---
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name:  {{ template "hmcts.releasename.v1" . }}
  {{- ( include "hmcts.labels.v1" . ) | indent 2 }}
spec:
  {{ if .Values.pdb.minAvailable }}
  minAvailable: {{ .Values.pdb.minAvailable }}
  {{- else -}}
  maxUnavailable: {{ .Values.pdb.maxUnavailable }}
  {{- end }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ template "hmcts.releasename.v1" . }}
{{- end }}
{{- end }}

{{- define "hmcts.pdb.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.pdb.v1.tpl") -}}
{{- end -}}