{{- define "hmcts.container.v1.tpl" -}}
- image: {{ required "An image must be supplied to the chart" .Values.image }}
  name: {{ template "hmcts.releasename.v1" . }}
  securityContext:
    allowPrivilegeEscalation: false
  env:
      {{- ( include "hmcts.secrets.v1" .) | indent 4 }}
      {{- range $key, $val := .Values.environment }}
    - name: {{ $key }}
      value: {{ tpl ($val | quote) $ }}
      {{- end}}
  {{- if .Values.configmap }}
  envFrom:
    - configMapRef:
        name: {{ template "hmcts.releasename.v1" . }}
  {{- end }}
  {{- ( include "hmcts.secretMounts.v1" . ) | indent 2 }}
  {{if .Values.global.devMode -}}
  resources:
    requests:
      memory: {{ .Values.devmemoryRequests | quote }}
      cpu: {{ .Values.devcpuRequests | quote }}
    limits:
      memory: {{ .Values.devmemoryLimits | quote }}
      cpu: {{ .Values.devcpuLimits | quote }}
  {{- else -}}
  resources:
    requests:
      memory: {{ .Values.memoryRequests | quote }}
      cpu: {{ .Values.cpuRequests | quote }}
    limits:
      memory: {{ .Values.memoryLimits | quote }}
      cpu: {{ .Values.cpuLimits | quote }}
  {{- end }}
  {{- if .Values.applicationPort }}
  ports:
    - containerPort: {{ .Values.applicationPort }}
      name: http
  {{- end }}
  {{- if .Values.livenessPath }}
  livenessProbe:
    httpGet:
      path: {{ .Values.livenessPath }}
      port: {{ .Values.applicationPort }}
    initialDelaySeconds: {{ .Values.livenessDelay }}
    timeoutSeconds: {{ .Values.livenessTimeout }}
    periodSeconds: {{ .Values.livenessPeriod }}
    failureThreshold: {{ .Values.livenessFailureThreshold }}
  {{- end }}
  {{- if .Values.readinessPath }}
  readinessProbe:
    httpGet:
      path: {{ .Values.readinessPath }}
      port: {{ .Values.applicationPort }}
    initialDelaySeconds: {{ .Values.readinessDelay }}
    timeoutSeconds: {{ .Values.readinessTimeout }}
    periodSeconds: {{ .Values.readinessPeriod }}
  {{- end }}
  imagePullPolicy: {{.Values.imagePullPolicy}}
{{- end -}}

{{- define "hmcts.container.v1" -}}
{{- /* clear new line so indentation works correctly */ -}}
{{- println "" -}}
{{- include "hmcts.util.merge.v1" (append . "hmcts.container.v1.tpl") | indent 6 -}}
{{- end -}}