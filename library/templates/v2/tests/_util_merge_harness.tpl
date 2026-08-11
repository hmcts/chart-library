{{/*
Fixtures for util_merge_test.yaml. Simulate a consumer chart's override
templates, since exercising hmcts.util.merge.v2 requires calling a wrapper
name (e.g. hmcts.configmap.v2) with a real override to merge against - nothing
in this chart's own rendering does that otherwise.
*/}}

{{/* Sets one field; the rest should fall back to the library default. */}}
{{- define "hmcts.tests.configmapOverride.v1" -}}
injectedByConsumerOverride: "true"
{{- end -}}

{{/* Renders empty; should fall back entirely to the library default. */}}
{{- define "hmcts.tests.emptyOverride.v1" -}}
{{- end -}}
