{{- define "events-processor.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "events-processor.chart" -}}
{{- .Chart.Name | replace "-" " " | title -}}
{{- end -}}

{{- define "events-processor.release" -}}
{{- .Release.Name -}}
{{- end -}}
