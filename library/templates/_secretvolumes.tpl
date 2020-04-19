{{/*
The bit of templating needed to create the flex-Volume keyvault for mounting
*/}}
{{- define "hmcts.secretVolumes.v1" }}
{{- if and .Values.keyVaults .Values.global.enableKeyVaults }}
{{- $globals := .Values.global }}
{{- $keyVaults := .Values.keyVaults }}
{{- $aadIdentityName := .Values.aadIdentityName }}
volumes:
{{- range $vault, $info := .Values.keyVaults }}
  - name: {{ $vault }}
    flexVolume:
      driver: "azure/kv"
      {{- if not $aadIdentityName }}
      secretRef:
        name: {{ default "kvcreds" $keyVaults.secretRef }}
      {{- end}}
      options:
        usepodidentity: "{{ if $aadIdentityName }}true{{ else }}false{{ end}}"
        tenantid: {{ $globals.tenantId | quote }}
        keyvaultname: "{{ $vault }}{{ if not (default $info.excludeEnvironmentSuffix false) }}-{{ $globals.environment }}{{ end }}"
        keyvaultobjectnames: "{{range $index, $secret := $info.secrets }}{{if $index}};{{end}}{{ $secret }}{{ end }}"
        keyvaultobjecttypes: "{{range $index, $secret := $info.secrets }}{{if $index}};{{end}}secret{{ end }}"
{{- end }}
{{- end }}
{{- end }}

{{/*
Mount the Key vaults on /mnt/secrets
*/}}
{{- define "hmcts.secretMounts.v1" -}}
{{- if and .Values.keyVaults .Values.global.enableKeyVaults }}
volumeMounts:
{{- range $vault, $info := .Values.keyVaults }}
  - name: {{ $vault | quote }}
    mountPath: "/mnt/secrets/{{ $vault }}"
    readOnly: true
{{- end }}
{{- end }}
{{- end }}