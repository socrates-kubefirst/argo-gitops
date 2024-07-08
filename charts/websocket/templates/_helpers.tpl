{{/*
Expand the name of the chart.
*/}}
{{- define "websocket.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fullname.
*/}}
{{- define "websocket.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "websocket.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the chart name.
*/}}
{{- define "websocket.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "websocket.labels" -}}
helm.sh/chart: {{ include "websocket.chart" . }}
{{ include "websocket.name" . }}-version: {{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ include "websocket.name" . }}
{{- end -}}
