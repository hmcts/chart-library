{{/*
The bit of templating needed to create the CSI driver keyvault for mounting
*/}}
{{- define "hmcts.secretCSIVolumes.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) }}
{{- $globals := $languageValues.global }}
{{- $keyVaults := $languageValues.keyVaults }}
{{- $root := . }}
volumes:
{{- range $vault, $info := $languageValues.keyVaults }}
{{- if not $info.disabled }}
  - name: vault-{{ $vault }}
    csi:
      driver: "secrets-store.csi.k8s.io"
      readOnly: true
      volumeAttributes:
        secretProviderClass: {{ template "hmcts.releasename.v2" $root }}-{{ $vault }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
*/}}
{{- define "hmcts.tolerations.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if $languageValues.tolerations }}
tolerations:
{{- range $languageValues.tolerations }}
  - key: {{ .key }}
    effect: {{ .effect }}
    operator: {{ .operator }}
    value: {{ .value }}
{{- end }}
{{- end }}
{{- end }}
