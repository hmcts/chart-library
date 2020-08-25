{{- /*
releasename defines a suitably unique name for a resource by combining
the release name and the chart name.
The prevailing wisdom is that names should only contain a-z, 0-9 plus dot (.) and dash (-), and should
not exceed 63 characters.
Parameters:
- .Values.releaseNameOverride: Replaces the computed name with this given name
- .Values.releaseNamePrefix: Prefix
- .Values.global.releaseNamePrefix: Global prefix
- .Values.releaseNameSuffix: Suffix
- .Values.global.releaseNameSuffix: Global suffix
The applied order is: "global prefix + prefix + name + suffix + global suffix"
Usage: 'name: "{{- template "hmcts.releasename.v1" . -}}"'
*/ -}}
{{- define "hmcts.releasename.v1" }}
  {{- $global := default (dict) .Values.global -}}
  {{- $base := printf "%s-%s" .Release.Name .Chart.Name -}}
  {{- if .Values.releaseNameOverride -}}
  {{- $base = tpl .Values.releaseNameOverride $ -}}  
  {{- end -}}
  {{- $gpre := default "" $global.releaseNamePrefix -}}
  {{- $pre := default "" .Values.releaseNamePrefix -}}
  {{- $suf := default "" .Values.releaseNameSuffix -}}
  {{- $gsuf := default "" $global.releaseNameSuffix -}}
  {{- $name := print $gpre $pre $base $suf $gsuf -}}
  {{- $name | lower | trunc 63 | trimSuffix "-" -}}
{{- end -}}
