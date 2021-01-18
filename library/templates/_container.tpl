{{- define "hmcts.container.v1.tpl" -}}
{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
- image: {{ required "An image must be supplied to the chart" $languageValues.image }}
  name: {{ template "hmcts.releasename.v1" . }}
  securityContext:
    allowPrivilegeEscalation: false
  env:
    {{- if $languageValues.global.devMode }}
    - name: {{ $languageValues.devApplicationInsightsInstrumentKeyName }}
      value: {{ $languageValues.devApplicationInsightsInstrumentKey | quote }}
    {{- end -}}
      {{- ( include "hmcts.secrets.v1" .) | indent 4 }}
      {{- range $key, $val := $languageValues.environment }}
    - name: {{ $key }}
      value: {{ tpl ($val | quote) $ }}
      {{- end}}
  {{- if .configmap }}
  envFrom:
    - configMapRef:
        name: {{ template "hmcts.releasename.v1" . }}
  {{- end }}
  {{- ( include "hmcts.secretMounts.v1" . ) | indent 2 }}
  {{if $languageValues.global.devMode -}}
  resources:
    requests:
      memory: {{ $languageValues.devmemoryRequests | quote }}
      cpu: {{  $languageValues.devcpuRequests | quote }}
    limits:
      memory: {{ $languageValues.devmemoryLimits | quote }}
      cpu: {{ $languageValues.devcpuLimits | quote }}
  {{- else -}}
  resources:
    requests:
      memory: {{ $languageValues.memoryRequests | quote }}
      cpu: {{ $languageValues.cpuRequests | quote }}
    limits:
      memory: {{ $languageValues.memoryLimits | quote }}
      cpu: {{ $languageValues.cpuLimits | quote }}
  {{- end }}
  {{- if $languageValues.applicationPort }}
  ports:
    - containerPort: {{ $languageValues.applicationPort }}
      name: http
  {{- end }}
  {{- if $languageValues.livenessPath }}
  livenessProbe:
    httpGet:
      path: {{ $languageValues.livenessPath }}
      port: {{ $languageValues.applicationPort }}
    initialDelaySeconds: {{ $languageValues.livenessDelay }}
    timeoutSeconds: {{ $languageValues.livenessTimeout }}
    periodSeconds: {{ $languageValues.livenessPeriod }}
    failureThreshold: {{ $languageValues.livenessFailureThreshold }}
  {{- end }}
  {{- if $languageValues.readinessPath }}
  readinessProbe:
    httpGet:
      path: {{ $languageValues.readinessPath }}
      port: {{ $languageValues.applicationPort }}
    initialDelaySeconds: {{ $languageValues.readinessDelay }}
    timeoutSeconds: {{ $languageValues.readinessTimeout }}
    periodSeconds: {{ $languageValues.readinessPeriod }}
  {{- end }}
  imagePullPolicy: {{$languageValues.imagePullPolicy}}
{{- end -}}

{{- define "hmcts.container.v1" -}}
{{- /* clear new line so indentation works correctly */ -}}
{{- println "" -}}
{{- include "hmcts.util.merge.v1" (append . "hmcts.container.v1.tpl") | indent 6 -}}
{{- end -}}