{{/*
The bit of templating needed to create the CSI driver keyvault for mounting
*/}}
{{- define "hmcts.secretCSIVolumes.v3" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) }}
{{- $globals := $languageValues.global }}
{{- $keyVaults := $languageValues.keyVaults }}
{{- $root := . }}
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
Mount the Key vaults on /mnt/secrets by default or the custom mountPath
*/}}
{{- define "hmcts.secretMounts.v3" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) }}
{{- range $vault, $info := $languageValues.keyVaults }}
{{- if not $info.disabled }}
  - name: vault-{{ $vault }}
    mountPath: "{{ default (printf "/mnt/secrets/%s" $vault) $info.mountPath }}"
    readOnly: true
{{- end }}
{{- end }}
{{- end }}
{{- end }}
