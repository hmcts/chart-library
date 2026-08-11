{{- define "hmcts.secretproviderclass-tests.v4.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- $testsConfig := default dict $languageValues.testsConfig -}}
{{- $globals := default dict $languageValues.global -}}
{{- $testsKeyVaults := get $testsConfig "keyVaults" -}}
{{- if and $testsKeyVaults (get $globals "enableKeyVaults") (not $languageValues.disableKeyVaults) -}}
{{- $root := . -}}
{{- range $vault, $info := $testsKeyVaults }}
{{- if not $info.disabled }}
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: {{ template "hmcts.releasename.v3" $root }}-tests-{{ $vault }}
spec:
  provider: azure
  parameters:
    userAssignedIdentityID: ""
    usePodIdentity: "true"
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

{{- define "hmcts.secretproviderclass-tests.v4" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.secretproviderclass-tests.v4.tpl") -}}
{{- end -}}
