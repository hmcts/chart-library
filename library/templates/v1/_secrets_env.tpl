{{/*
Adding in the helper here where we can use a secret object to include secrets to for the deployed service.
The key or "environment variable" must be uppercase and contain only numbers or "_".
Example format:
"
 ENVIRONMENT_VAR:
    secretRef: secret-vault 
    key: connectionString
    disabled: false
"
*/}}
{{- define "hmcts.secrets.v1" -}}

  {{- if .Values.secrets -}}
    {{- range $key, $val := .Values.secrets }}
      {{- if and $val (not $val.disabled) }}
- name: {{ if $key | regexMatch "^[^.-]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
        {{- end }}
  valueFrom:
    secretKeyRef:
      name: {{  tpl (required "Each item in \"secrets:\" needs a secretRef member" $val.secretRef) $ }}
      key: {{ required "Each item in \"secrets:\" needs a key member" $val.key }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end }}