{{- define "hmcts.secretproviderclass.v3.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- if and $languageValues.keyVaults $languageValues.global.enableKeyVaults (not $languageValues.disableKeyVaults) -}}
{{- $globals := $languageValues.global -}}
{{- $keyVaults := $languageValues.keyVaults -}}
{{- $root := . -}}
{{- range $vault, $info := $languageValues.keyVaults }}
{{- if not $info.disabled }}
---
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: {{ template "hmcts.releasename.v2" $root }}-{{ $vault }}
spec:
  provider: azure
  parameters:
    userAssignedIdentityID: ""
  {{- if $languageValues.useWorkloadIdentity }}
    clientID: {{ $languageValues.workloadClientID }}
  {{- else }}
    usePodIdentity: "true" 
  {{- end }}
    keyvaultName: "{{ $vault }}{{ if not (default $info.excludeEnvironmentSuffix false) }}-{{ $globals.environment }}{{ end }}"
    objects: |
      array: {{- range $info.secrets }}
     {{- if kindIs "map" . }}
        - |
        {{- if $globals.environment }}
          objectName: {{ .name | replace "<ENV>" $globals.environment }} 
        {{- else }}
          objectName: {{ .name }}
        {{- end }}
          objectType: secret
        {{- if hasKey . "alias" }}
          objectAlias: {{ .alias }}
        {{- end }}
     {{- else }}
        - |
        {{- if $globals.environment }}
          objectName: {{ . | replace "<ENV>" $globals.environment }} 
        {{- else }}
          objectName: {{ . }}
        {{- end }} 
          objectType: secret
     {{- end }}
      {{- end }}

      {{- range $info.certs }}
     {{- if kindIs "map" . }}
        - |
          objectName: {{ .name }}
          objectType: cert
        {{- if hasKey . "alias" }}
          objectAlias: {{ .alias }}
        {{- end }}
     {{- else }}
        - |
          objectName: {{ . }}
          objectType: cert
     {{- end }}
      {{- end }}
    tenantId: {{ $globals.tenantId | quote }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "hmcts.secretproviderclass.v3" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.secretproviderclass.v3.tpl") -}}
{{- end -}}
