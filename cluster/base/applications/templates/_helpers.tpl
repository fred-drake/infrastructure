{{- if eq .Values.applicationType "core" -}}
    {{- define "apps.applicationList" -}}
        {{- .Values.applications.core -}}
    {{- end -}}
{{- else -}}
    {{- define "apps.applicationList" -}}
        {{- .Values.applications.service -}}
    {{- end -}}
{{- end -}}
