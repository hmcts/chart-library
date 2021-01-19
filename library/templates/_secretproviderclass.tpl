{{- define "hmcts.secretproviderclass.v1.tpl" -}}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) -}}
{{- $globals := $languageValues.global -}}
{{- $keyVaults := $languageValues.keyVaults -}}
{{- $root := . -}}
{{- range $vault, $info := $languageValues.keyVaults }}
---
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