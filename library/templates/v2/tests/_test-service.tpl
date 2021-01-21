{{- define "hmcts.testservice.v2.tpl" -}}
apiVersion: v1
kind: Pod
metadata:
  name: {{ template "hmcts.releasename.v2" . }}-test
  annotations:
    "helm.sh/hook": test-success
spec:
  containers:
  - name: {{ template "hmcts.releasename.v2" . }}-test
    image: busybox
    env:
      - name: SERVICE_NAME
        value: {{ template "hmcts.releasename.v2" . }}
    command: ["sh", "-c", "httpstatuscode=$(wget -S http://$SERVICE_NAME/health 2>&1 | grep HTTP/ | awk 'END{print $2}') && [ \"$httpstatuscode\" = \"200\" ]"]
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 100m
        memory: 128Mi
  restartPolicy: Never
{{- end -}}

{{- define "hmcts.testservice.v2" -}}
{{- template "hmcts.util.merge.v2" (append . "hmcts.testservice.v2.tpl") -}}
{{- end -}}
