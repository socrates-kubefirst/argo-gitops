{{- define "snowplow-kafka-pg-loader.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "snowplow-kafka-pg-loader.chart" -}}
{{- .Chart.Name | replace "-" " " | title -}}
{{- end -}}

{{- define "snowplow-kafka-pg-loader.release" -}}
{{- .Release.Name -}}
{{- end -}}
