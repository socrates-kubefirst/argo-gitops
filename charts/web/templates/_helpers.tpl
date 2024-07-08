{{- define "web.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "web.chart" -}}
{{- .Chart.Name | replace "-" " " | title -}}
{{- end -}}

{{- define "web.release" -}}
{{- .Release.Name -}}
{{- end -}}

{{- define "web.ingress" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "web.fullname" . }}-ingress
  labels:
    {{- include "web.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  rules:
  {{- range .Values.ingress.hosts }}
  - host: {{ .host }}
    http:
      paths:
      {{- range .paths }}
      - path: {{ .path }}
        pathType: {{ .pathType }}
        backend:
          service:
            name: {{ include "web.fullname" $.Release.Name }}
            port:
              number: 80
      {{- end }}
  {{- end }}
  {{- with .Values.ingress.tls }}
  tls:
  {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
