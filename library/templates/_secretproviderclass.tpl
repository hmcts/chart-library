{{- define "hmcts.secretproviderclass.v1.tpl" -}}
{{- if and .Values.keyVaults .Values.global.enableKeyVaults (not .Values.disableKeyVaults) }}
{{- $globals := .Values.global }}
{{- $keyVaults := .Values.keyVaults }}
{{- $root := . }}
{{- range $vault, $info := .Values.keyVaults }}
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: {{ template "hmcts.releasename.v1" $root }}-{{ $vault }}
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
    tenantId: {{ $globals.tenantId | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "hmcts.secretproviderclass.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.secretproviderclass.v1.tpl") -}}
{{- end -}}