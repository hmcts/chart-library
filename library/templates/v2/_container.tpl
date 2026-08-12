{{- define "hmcts.container.v4.tpl" -}}
{{- $languageValues := deepCopy .Values -}}
{{- if hasKey .Values "language" -}}
{{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) ) -}}
{{- end -}}
{{- $globals := $languageValues.global | default dict -}}
- image: {{ required "An image must be supplied to the chart" $languageValues.image }}
  name: {{ template "hmcts.releasename.v3" . }}
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
    {{- if and $globals.devMode $languageValues.devApplicationInsightsInstrumentKeyName }}
    - name: {{ $languageValues.devApplicationInsightsInstrumentKeyName }}
      value: {{ $languageValues.devApplicationInsightsInstrumentKey | quote }}
    {{- end -}}
      {{- ( include "hmcts.secrets.v3" .) | indent 4 }}
      {{- range $key, $val := $languageValues.environment }}
    - name: {{ $key }}
      value: {{ tpl ($val | quote) $ }}
      {{- end}}
  {{- if or ($languageValues.configmap) ($languageValues.envFromSecret) }}
  envFrom:
  {{- if $languageValues.configmap }}
    - configMapRef:
       name: {{ template "hmcts.releasename.v3" . }}
  {{- end }}
  {{- if $languageValues.envFromSecret }}
    - secretRef:
        name: {{ $languageValues.envFromSecret }}
  {{- end }}
  {{- end }}
  {{- $vMounts := trim (printf "%s%s" (include "hmcts.volumeMounts.v3" .) (include "hmcts.secretMounts.v4" .)) }}
  {{- if $vMounts }}
  volumeMounts:
  {{- ( include "hmcts.volumeMounts.v3" . ) | indent 2 }}
  {{- ( include "hmcts.secretMounts.v4" . ) | indent 2 }}
  {{- end }}
  {{- if or ($globals.devMode) ($languageValues.memoryRequests) ($languageValues.cpuRequests) ($languageValues.memoryLimits) ($languageValues.cpuLimits) }}
  {{- if $globals.devMode }}
  resources:
    requests:
      memory: {{ $languageValues.devmemoryRequests | quote }}
      cpu: {{ $languageValues.devcpuRequests | quote }}
    limits:
      memory: {{ $languageValues.devmemoryLimits | quote }}
      cpu: {{ $languageValues.devcpuLimits | quote }}
  {{- else }}
  resources:
    requests:
      memory: {{ $languageValues.memoryRequests | quote }}
      cpu: {{ $languageValues.cpuRequests | quote }}
    limits:
      memory: {{ $languageValues.memoryLimits | quote }}
      cpu: {{ $languageValues.cpuLimits | quote }}
  {{- end }}
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
    initialDelaySeconds: {{ $languageValues.startupDelay | default 0 }}
    timeoutSeconds: {{ $languageValues.startupTimeout | default 3 }}
    periodSeconds: {{ $languageValues.startupPeriod | default 10 }}
    failureThreshold: {{ $languageValues.startupFailureThreshold | default 20 }}
  {{- end }}
  {{- if $languageValues.livenessPath }}
  livenessProbe:
    httpGet:
      path: {{ $languageValues.livenessPath }}
      port: {{ $languageValues.applicationPort }}
    initialDelaySeconds: {{ $languageValues.livenessDelay | default 0 }}
    timeoutSeconds: {{ $languageValues.livenessTimeout | default 3 }}
    periodSeconds: {{ $languageValues.livenessPeriod | default 15 }}
    failureThreshold: {{ $languageValues.livenessFailureThreshold | default 3 }}
  {{- end }}
  {{- if $languageValues.readinessPath }}
  readinessProbe:
    httpGet:
      path: {{ $languageValues.readinessPath }}
      port: {{ $languageValues.applicationPort }}
    initialDelaySeconds: {{ $languageValues.readinessDelay | default 0 }}
    timeoutSeconds: {{ $languageValues.readinessTimeout | default 3 }}
    periodSeconds: {{ $languageValues.readinessPeriod | default 15 }}
  {{- end }}
  imagePullPolicy: {{ $languageValues.imagePullPolicy | default "IfNotPresent" }}
{{- end -}}

{{- define "hmcts.container.v4" -}}
{{- /* clear new line so indentation works correctly */ -}}
{{- println "" -}}
{{- include "hmcts.util.merge.v2" (append . "hmcts.container.v4.tpl") | indent 6 -}}
{{- end -}}