{{- define "websocket.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "websocket.chart" -}}
{{- .Chart.Name | replace "-" " " | title -}}
{{- end -}}

{{- define "websocket.release" -}}
{{- .Release.Name -}}
{{- end -}}

{{- define "websocket.ingress" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "websocket.fullname" . }}-ingress
  labels:
    {{- include "websocket.labels" . | nindent 4 }}
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
            name: {{ include "websocket.fullname" $.Release.Name }}
            port:
              number: 8000
      {{- end }}
  {{- end }}
  {{- with .Values.ingress.tls }}
  tls:
  {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
