{{- if eq .Values.applicationType "core" -}}
    {{- define "applicationList" -}}
        {{- .Values.applications.core -}}
    {{- end -}}
{{- else -}}
    {{- define "applicationList" -}}
        {{- .Values.applications.service -}}
    {{- end -}}
{{- end -}}
