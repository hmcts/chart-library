{{/*
The bit of templating needed to create the flex-Volume keyvault for mounting
*/}}
{{- define "hmcts.secretCSIVolumes.v1" }}
{{- if and .Values.keyVaults .Values.global.enableKeyVaults (not .Values.disableKeyVaults) }}
{{- $globals := .Values.global }}
{{- $keyVaults := .Values.keyVaults }}
volumes:
{{- range $vault, $info := .Values.keyVaults }}
  - name: vault-{{ $vault }}
    csi:
      driver: "secrets-store.csi.k8s.io"
      readOnly: true
      volumeAttributes:
        providerName: "azure"
        usePodIdentity: "true"
        keyvaultName: "{{ $vault }}{{ if not (default $info.excludeEnvironmentSuffix false) }}-{{ $globals.environment }}{{ end }}"
        objects: |
          array: {{- range $info.secrets }}
            - |
              objectName: {{ . }}
              objectType: secret
          {{- end }}
        tenantid: {{ $globals.tenantId | quote }}
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