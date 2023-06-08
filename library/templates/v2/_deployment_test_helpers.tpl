{{- define "hmcts.tests.meta.v2" -}}
metadata:
  name: {{ .Release.Name }}-{{ .Values.task }}{{ .Values.type }}-job
  labels:
    app.kubernetes.io/managed-by: {{ .Release.Service }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
    app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}-{{ .Values.task }}{{ .Values.type }}
{{- end -}}

{{- define "hmcts.tests.header.v2" -}}
apiVersion: v1
kind: Pod
{{ template "hmcts.tests.meta.v2" . }}
    {{- if and .Values.aadIdentityName (not .Values.useWorkloadIdentity) }}
    aadpodidbinding: {{ .Values.aadIdentityName }}
    {{- end }}
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-delete-policy": before-hook-creation 
{{- end -}}

{{- define "hmcts.testscron.header.v2" -}}
apiVersion: batch/v1beta1
kind: CronJob
{{ template "hmcts.tests.meta.v2" . }}
spec:
  schedule: "{{ .Values.schedule }}"
  jobTemplate:
    spec:
      backoffLimit: 2
      template:
        metadata:
          labels:
            app.kubernetes.io/name: {{ template "hmcts.releasename.v2" . }}-{{ .Values.task }}testscron
            {{- if and .Values.aadIdentityName (not .Values.useWorkloadIdentity) }}
            aadpodidbinding: {{ .Values.aadIdentityName }}
            {{- end }}
        spec:
{{- end -}}

{{- define "hmcts.tests.spec.v2" -}}
{{- if and .Values.testsConfig.keyVaults .Values.global.enableKeyVaults }}
{{- $root := . }}
volumes:
{{- $globals := .Values.global }}
{{- $aadIdentityName := .Values.aadIdentityName }}
{{- range $key, $value := .Values.testsConfig.keyVaults }}
- name: vault-{{ $key }}
  csi:
    driver: "secrets-store.csi.k8s.io"
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ template "hmcts.releasename.v2" $root }}-tests-{{ $key }}
{{- end }}
{{- end }}
securityContext:
  runAsUser: 1000
  fsGroup: 1000
restartPolicy: Never
serviceAccountName: {{ .Values.testsConfig.serviceAccountName }}
containers:
  - name: tests
    image: {{ .Values.tests.image }}
    {{- if and .Values.testsConfig.keyVaults .Values.global.enableKeyVaults }}
    {{ $args := list }}
    {{- range $key, $value := .Values.testsConfig.keyVaults -}}{{- range $secret, $var := $value.secrets -}} {{ $args = append $args (printf "%s=%s/%s" (ternary ($var.name | upper |  replace "-" "_") $var.alias (empty $var.alias)) (ternary (printf "/mnt/secrets/%s" $key) $value.mountPath (empty $value.mountPath)) (ternary $var.name $var.alias (empty $var.alias)) | quote) }} {{- end -}}{{- end -}}
    args: [{{ $args | join "," }}]
    {{- end }}
    securityContext:
      allowPrivilegeEscalation: false
    {{- if or .Values.tests.environment .Values.testsConfig.environment }}
    {{- $envMap := dict "TEST_URL" "" -}}
    {{- if .Values.testsConfig.environment -}}{{- range $key, $value := .Values.testsConfig.environment -}}{{- $_ := set $envMap $key $value -}}{{- end -}}{{- end -}}
    {{- if .Values.tests.environment -}}{{- range $key, $value := .Values.tests.environment -}}{{- $_ := set $envMap $key $value -}}{{- end -}}{{- end }}
    env:
      - name: TASK
        value: {{ .Values.task | quote }}
      - name: TASK_TYPE
        value: {{ .Values.type | quote }}
      - name: SLACK_WEBHOOK
        valueFrom:
          secretKeyRef:
            name: tests-values
            key: slack-webhook
    {{- range $key, $val := $envMap }}
      - name: {{ $key }}
        value: {{ $val | quote }}
    {{- end }}
    {{- end }}
    {{- if and .Values.testsConfig.keyVaults .Values.global.enableKeyVaults }}
    volumeMounts:
    {{- range $key, $value := .Values.testsConfig.keyVaults }}
    - name: vault-{{ $key }}
      mountPath: {{ default (printf "/mnt/secrets/%s" $key) $value.mountPath }}
      readOnly: true
    {{- end }}
    {{- end }}
    resources:
      requests:
        memory: "{{ if .Values.tests.memoryRequests }}{{ .Values.tests.memoryRequests }}{{ else }}{{ .Values.testsConfig.memoryRequests }}{{ end }}"
        cpu: "{{ if .Values.tests.cpuRequests }}{{ .Values.tests.cpuRequests }}{{ else }}{{ .Values.testsConfig.cpuRequests }}{{ end }}"
      limits:
        memory: "{{ if .Values.tests.memoryLimits }}{{ .Values.tests.memoryLimits }}{{ else }}{{ .Values.testsConfig.memoryLimits }}{{ end }}"
        cpu: "{{ if .Values.tests.cpuLimits }}{{ .Values.tests.cpuLimits }}{{ else }}{{ .Values.testsConfig.cpuLimits }}{{ end }}"
{{- end -}}
