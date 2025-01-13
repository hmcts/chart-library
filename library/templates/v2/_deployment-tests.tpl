{{- define "hmcts.deploymenttests.v2.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{ if $languageValues.smoketests.enabled }}
---
{{ $smokedata := dict "Values" $languageValues "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $smokedata.Values "task" "smoke" }}
{{ $_ := set $smokedata.Values "type" "tests" }}
{{- include "hmcts.tests.header.v2" $smokedata }}
spec:
{{ $_ := set $smokedata.Values "tests" $languageValues.smoketests }}
{{- include "hmcts.tests.spec.v2" $smokedata | indent 2 }}
{{- end }}

{{ if $languageValues.functionaltests.enabled }}
---
{{ $functionaldata := dict "Values" $languageValues "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $functionaldata.Values "task" "functional" }}
{{ $_ := set $functionaldata.Values "type" "tests" }}
{{- include "hmcts.tests.header.v2" $functionaldata }}
spec:
{{ $_ := set $functionaldata.Values "tests" $languageValues.functionaltests }}
{{- include "hmcts.tests.spec.v2" $functionaldata | indent 2 }}
{{- end }}

{{ if and $languageValues.smoketestscron.enabled $languageValues.global.smoketestscron.enabled }}
---
{{ $smokedatacron := dict "Values" $languageValues "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $smokedatacron.Values "task" "smoke" }}
{{ $_ := set $smokedatacron.Values "schedule" $languageValues.smoketestscron.schedule }}
{{ $_ := set $smokedatacron.Values "type" "testscron" }}
{{- include "hmcts.testscron.header.v2" $smokedatacron }}
{{ $_ := set $smokedatacron.Values "tests" $languageValues.smoketestscron }}
{{- include "hmcts.tests.spec.v2" $smokedatacron | indent 10 }}
{{- end }}

{{ if and $languageValues.functionaltestscron.enabled $languageValues.global.functionaltestscron.enabled }}
---
{{ $functionaldatacron := dict "Values" $languageValues "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $functionaldatacron.Values "task" "functional" }}
{{ $_ := set $functionaldatacron.Values "schedule" $languageValues.functionaltestscron.schedule }}
{{ $_ := set $functionaldatacron.Values "type" "testscron" }}
{{- include "hmcts.testscron.header.v2" $functionaldatacron }}
{{ $_ := set $functionaldatacron.Values "tests" $languageValues.functionaltestscron }}
{{- include "hmcts.tests.spec.v2" $functionaldatacron | indent 10 }}
{{- end }}

{{- end -}}

{{- define "hmcts.deploymenttests.v2" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.deploymenttests.v2.tpl") -}}
{{- end -}}