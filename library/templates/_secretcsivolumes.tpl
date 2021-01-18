{{/*
The bit of templating needed to create the CSI driver keyvault for mounting
*/}}
{{- define "hmcts.secretCSIVolumes.v1" }}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) }}
{{- $globals := $languageValues.global }}
{{- $keyVaults := $languageValues.keyVaults }}
{{- $root := . }}
volumes:
{{- range $vault, $info := $languageValues.keyVaults }}
  - name: vault-{{ $vault }}
    csi:
      driver: "secrets-store.csi.k8s.io"
      readOnly: true
      volumeAttributes:
        secretProviderClass: {{ template "hmcts.releasename.v1" $root }}-{{ $vault }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Mount the Key vaults on /mnt/secrets
*/}}
{{- define "hmcts.secretMounts.v1" -}}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) }}
volumeMounts:
{{- range $vault, $info := $languageValues.keyVaults }}
  - name: vault-{{ $vault }}
    mountPath: "/mnt/secrets/{{ $vault }}"
    readOnly: true
{{- end }}
{{- end }}
{{- end }}