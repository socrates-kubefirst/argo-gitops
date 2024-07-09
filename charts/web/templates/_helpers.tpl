{{/*
Expand the name of the chart.
*/}}
{{- define "web.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fullname.
*/}}
{{- define "web.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "web.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the chart name.
*/}}
{{- define "web.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | quote -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "web.labels" -}}
helm.sh/chart: {{ include "web.chart" . }}
{{ include "web.name" . }}-version: "{{ .Chart.Version }}"
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/name: {{ include "web.name" . | quote }}
{{- end -}}
