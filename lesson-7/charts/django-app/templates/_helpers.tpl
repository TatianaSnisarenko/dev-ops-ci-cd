{{- define "django-app.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end }}

{{- define "django-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "django-app.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
