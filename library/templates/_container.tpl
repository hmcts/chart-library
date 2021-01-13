{{- define "hmcts.container.v1.tpl" -}}
{{- $globals := .Values.global }}
{{- $containerValues := (pluck .Values.language .Values | first | default .) -}}
{{- with $containerValues }}
- image: {{ required "An image must be supplied to the chart" .image }}
  name: {{ "test" }}
  securityContext:
    allowPrivilegeEscalation: false
  env:
    {{- if $globals.devMode }}
    - name: {{ .devApplicationInsightsInstrumentKeyName }}
      value: {{ .devApplicationInsightsInstrumentKey | quote }}
    {{- end -}}
      {{- range $key, $val := .environment }}
    - name: {{ $key }}
      value: {{ tpl ($val | quote) $ }}
      {{- end}}
  {{- if .configmap }}
  envFrom:
    - configMapRef:
        name: {{ "test" }}
  {{- end }}
  {{if $globals.devMode -}}
  resources:
    requests:
      memory: {{ .devmemoryRequests | quote }}
      cpu: {{  .devcpuRequests | quote }}
    limits:
      memory: {{ .devmemoryLimits | quote }}
      cpu: {{ .devcpuLimits | quote }}
  {{- else -}}
  resources:
    requests:
      memory: {{ .memoryRequests | quote }}
      cpu: {{ .cpuRequests | quote }}
    limits:
      memory: {{ .memoryLimits | quote }}
      cpu: {{ .cpuLimits | quote }}
  {{- end }}
  {{- if .applicationPort }}
  ports:
    - containerPort: {{ .applicationPort }}
      name: http
  {{- end }}
  {{- if .livenessPath }}
  livenessProbe:
    httpGet:
      path: {{ .livenessPath }}
      port: {{ .applicationPort }}
    initialDelaySeconds: {{ .livenessDelay }}
    timeoutSeconds: {{ .livenessTimeout }}
    periodSeconds: {{ .livenessPeriod }}
    failureThreshold: {{ .livenessFailureThreshold }}
  {{- end }}
  {{- if .readinessPath }}
  readinessProbe:
    httpGet:
      path: {{ .readinessPath }}
      port: {{ .applicationPort }}
    initialDelaySeconds: {{ .readinessDelay }}
    timeoutSeconds: {{ .readinessTimeout }}
    periodSeconds: {{ .readinessPeriod }}
  {{- end }}
  imagePullPolicy: {{.imagePullPolicy}}
 {{- end }}
{{- end -}}

{{- define "hmcts.container.v1" -}}
{{- /* clear new line so indentation works correctly */ -}}
{{- println "" -}}
{{- include "hmcts.util.merge.v1" (append . "hmcts.container.v1.tpl") | indent 6 -}}
{{- end -}}