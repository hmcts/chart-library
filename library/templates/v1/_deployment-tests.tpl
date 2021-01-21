{{- define "hmcts.deploymenttests.v1.tpl" -}}
{{ if .Values.smoketests.enabled }}
---
{{ $smokedata := dict "Values" .Values "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $smokedata.Values "task" "smoke" }}
{{ $_ := set $smokedata.Values "type" "tests" }}
{{- include "hmcts.tests.header" $smokedata }}
spec:
{{ $_ := set $smokedata.Values "tests" .Values.smoketests }}
{{- include "hmcts.tests.spec" $smokedata | indent 2 }}
{{- end }}

{{ if .Values.functionaltests.enabled }}
---
{{ $functionaldata := dict "Values" .Values "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $functionaldata.Values "task" "functional" }}
{{ $_ := set $functionaldata.Values "type" "tests" }}
{{- include "hmcts.tests.header" $functionaldata }}
spec:
{{ $_ := set $functionaldata.Values "tests" .Values.functionaltests }}
{{- include "hmcts.tests.spec" $functionaldata | indent 2 }}
{{- end }}

{{ if and .Values.smoketestscron.enabled .Values.global.smoketestscron.enabled }}
---
{{ $smokedatacron := dict "Values" .Values "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $smokedatacron.Values "task" "smoke" }}
{{ $_ := set $smokedatacron.Values "schedule" .Values.smoketestscron.schedule }}
{{ $_ := set $smokedatacron.Values "type" "testscron" }}
{{- include "hmcts.testscron.header" $smokedatacron }}
{{ $_ := set $smokedatacron.Values "tests" .Values.smoketestscron }}
{{- include "hmcts.tests.spec" $smokedatacron | indent 10 }}
{{- end }}

{{ if and .Values.functionaltestscron.enabled .Values.global.functionaltestscron.enabled }}
---
{{ $functionaldatacron := dict "Values" .Values "Release" .Release "Chart" .Chart "Template" .Template "Files" .Files }}
{{ $_ := set $functionaldatacron.Values "task" "functional" }}
{{ $_ := set $functionaldatacron.Values "schedule" .Values.functionaltestscron.schedule }}
{{ $_ := set $functionaldatacron.Values "type" "testscron" }}
{{- include "hmcts.testscron.header" $functionaldatacron }}
{{ $_ := set $functionaldatacron.Values "tests" .Values.functionaltestscron }}
{{- include "hmcts.tests.spec" $functionaldatacron | indent 10 }}
{{- end }}

{{- end -}}

{{- define "hmcts.deploymenttests.v1" -}}
{{- template "hmcts.util.merge.v1" (append . "hmcts.deploymenttests.v1.tpl") -}}
{{- end -}}