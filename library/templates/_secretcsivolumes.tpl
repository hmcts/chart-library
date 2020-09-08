{{/*
The bit of templating needed to create the CSI driver keyvault for mounting
*/}}
{{- define "hmcts.secretCSIVolumes.v1" }}
{{- if and .Values.keyVaults .Values.global.enableKeyVaults (not .Values.disableKeyVaults) }}
{{- $globals := .Values.global }}
{{- $keyVaults := .Values.keyVaults }}
{{- $root := . }}
volumes:
{{- range $vault, $info := .Values.keyVaults }}
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
{{- if and .Values.keyVaults .Values.global.enableKeyVaults (not .Values.disableKeyVaults) }}
volumeMounts:
{{- range $vault, $info := .Values.keyVaults }}
  - name: vault-{{ $vault }}
    mountPath: "/mnt/secrets/{{ $vault }}"
    readOnly: true
{{- end }}
{{- end }}
{{- end }}