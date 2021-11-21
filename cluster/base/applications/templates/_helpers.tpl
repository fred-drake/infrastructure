{{- if eq .Values.applicationType "core" -}}
    {{- $applicationList := .Values.applications.core -}}
{{- else -}}
    {{- $applicationList := .Values.applications.service -}}
{{- end -}}
