{{- define "hmcts.secretproviderclass.v1.tpl" -}}
{{- range $vault, $info := .Values.keyVaults }}
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
{{- if and .Values.keyVaults .Values.global.enableKeyVaults (not .Values.disableKeyVaults) }}
{{- $globals := .Values.global }}
{{- $keyVaults := .Values.keyVaults }}
metadata:
  name: vault-{{ $vault }}
spec:
  provider: azure
  parameters:
    userAssignedIdentityID: ""
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