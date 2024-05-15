{{- define "hmcts.container.v3.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
- image: {{ required "An image must be supplied to the chart" $languageValues.image }}
  name: {{ template "hmcts.releasename.v2" . }}
  securityContext:
    allowPrivilegeEscalation: false
  {{- if $languageValues.args }}
  args:
{{ toYaml $languageValues.args | indent 4 }}
  {{- end}}
  {{- if $languageValues.command }}
  command:
{{ toYaml $languageValues.command | indent 4 }}
  {{- end}}
  env:
    {{- if and $languageValues.global.devMode $languageValues.devApplicationInsightsInstrumentKeyName }}
    - name: {{ $languageValues.devApplicationInsightsInstrumentKeyName }}
      value: {{ $languageValues.devApplicationInsightsInstrumentKey | quote }}
    {{- end -}}
      {{- ( include "hmcts.secrets.v2" .) | indent 4 }}
      {{- range $key, $val := $languageValues.environment }}
    - name: {{ $key }}
      value: {{ tpl ($val | quote) $ }}
      {{- end}}
  {{- if or ($languageValues.configmap) ($languageValues.envFromSecret) }}
  envFrom:
  {{- if $languageValues.configmap }}
    - configMapRef:
       name: {{ template "hmcts.releasename.v2" . }}
  {{- end }}
  {{- if $languageValues.envFromSecret }}
    - secretRef:
        name: {{ $languageValues.envFromSecret }}
  {{- end }}
  {{- end }}
  volumeMounts:
  {{- ( include "hmcts.volumeMounts.v2" . ) | indent 2 }}
  {{- ( include "hmcts.secretMounts.v3" . ) | indent 2 }}
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
  {{- if $languageValues.startupPath }}
  startupProbe:
    httpGet:
      path: {{ $languageValues.startupPath }}
      port: {{ $languageValues.applicationPort }}
    initialDelaySeconds: {{ $languageValues.startupDelay }}
    timeoutSeconds: {{ $languageValues.startupTimeout }}
    periodSeconds: {{ $languageValues.startupPeriod }}
    failureThreshold: {{ $languageValues.startupFailureThreshold }}
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

{{- define "hmcts.container.v2" -}}
{{- /* clear new line so indentation works correctly */ -}}
{{- println "" -}}
{{- include "hmcts.util.merge.v2" (append . "hmcts.container.v3.tpl") | indent 6 -}}
{{- end -}}