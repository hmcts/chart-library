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
Usage: 'name: "{{- template "hmcts.releasename.v2" . -}}"'
*/ -}}
{{- define "hmcts.releasename.v2" }}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
  {{- $global := default (dict) $languageValues .global -}}
  {{- $base := printf "%s-%s" .Release.Name .Chart.Name -}}
  {{- if $languageValues.releaseNameOverride -}}
  {{- $base = tpl $languageValues.releaseNameOverride $ -}}  
  {{- end -}}
  {{- $gpre := default "" $global.releaseNamePrefix -}}
  {{- $pre := default "" $languageValues.releaseNamePrefix -}}
  {{- $suf := default "" $languageValues.releaseNameSuffix -}}
  {{- $gsuf := default "" $global.releaseNameSuffix -}}
  {{- $name := print $gpre $pre $base $suf $gsuf -}}
  {{- $name | lower | trunc 63 | trimSuffix "-" -}}
{{- end -}}
