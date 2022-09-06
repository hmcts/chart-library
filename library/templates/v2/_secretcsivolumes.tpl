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
  - name: vault-{{ default $vault $info.alias }}
    csi:
      driver: "secrets-store.csi.k8s.io"
      readOnly: true
      volumeAttributes:
        secretProviderClass: {{ template "hmcts.releasename.v2" $root }}-{{ default $vault $info.alias }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Mount the Key vaults on /mnt/secrets by Default or the custom path
*/}}
{{- define "hmcts.secretMounts.v2" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) }}
volumeMounts:
{{- range $vault, $info := $languageValues.keyVaults }}
{{- if not $info.disabled }}
  - name: vault-{{ default $vault $info.alias }}
    mountPath: "{{ default "/mnt/secrets/" $info.mountPath }}{{ default $vault $info.alias }}"
    readOnly: true
{{- end }}
{{- end }}
{{- end }}
{{- end }}
