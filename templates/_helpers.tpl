{{/*
Expand the name of the chart.
*/}}
{{- define "peering-manager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "peering-manager.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "peering-manager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "peering-manager.labels" -}}
helm.sh/chart: {{ include "peering-manager.chart" . }}
{{ include "peering-manager.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "peering-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "peering-manager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "peering-manager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "peering-manager.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret that contains the PostgreSQL password
*/}}
{{- define "peering-manager.postgresql.secret" -}}
  {{- if .Values.postgresql.enabled }}
    {{- include "postgresql.secretName" .Subcharts.postgresql -}}
  {{- else if .Values.externalDatabase.existingSecretName }}
    {{- .Values.externalDatabase.existingSecretName }}
  {{- else }}
    {{- .Values.existingSecret | default (include "peering-manager.fullname" .) }}
  {{- end }}
{{- end }}

{{/*
Name of the key in Secret that contains the PostgreSQL password
*/}}
{{- define "peering-manager.postgresql.secretKey" -}}
  {{- if .Values.postgresql.enabled -}}
    {{- include "postgresql.userPasswordKey" .Subcharts.postgresql -}}
  {{- else if .Values.externalDatabase.existingSecretName -}}
    {{- .Values.externalDatabase.existingSecretKey -}}
  {{- else -}}
    db_password
  {{- end -}}
{{- end }}

{{/*
Name of the Secret that contains the Redis tasks password
*/}}
{{- define "peering-manager.tasksRedis.secret" -}}
  {{- if .Values.redis.enabled }}
    {{- include "redis.secretName" .Subcharts.redis -}}
  {{- else if .Values.tasksRedis.existingSecretName }}
    {{- .Values.tasksRedis.existingSecretName }}
  {{- else }}
    {{- .Values.existingSecret | default (include "peering-manager.fullname" .) }}
  {{- end }}
{{- end }}

{{/*
Name of the key in Secret that contains the Redis tasks password
*/}}
{{- define "peering-manager.tasksRedis.secretKey" -}}
  {{- if .Values.redis.enabled -}}
    {{- include "redis.secretPasswordKey" .Subcharts.redis -}}
  {{- else if .Values.tasksRedis.existingSecretName -}}
    {{ .Values.tasksRedis.existingSecretKey }}
  {{- else -}}
    redis_tasks_password
  {{- end -}}
{{- end }}

{{/*
Name of the Secret that contains the Redis cache password
*/}}
{{- define "peering-manager.cachingRedis.secret" -}}
  {{- if .Values.redis.enabled }}
    {{- include "redis.secretName" .Subcharts.redis -}}
  {{- else if .Values.cachingRedis.existingSecretName }}
    {{- .Values.cachingRedis.existingSecretName }}
  {{- else }}
    {{- .Values.existingSecret | default (include "peering-manager.fullname" .) }}
  {{- end }}
{{- end }}

{{/*
Name of the key in Secret that contains the Redis cache password
*/}}
{{- define "peering-manager.cachingRedis.secretKey" -}}
  {{- if .Values.redis.enabled -}}
    {{- include "redis.secretPasswordKey" .Subcharts.redis -}}
  {{- else if .Values.cachingRedis.existingSecretName -}}
    {{ .Values.cachingRedis.existingSecretKey }}
  {{- else -}}
    redis_cache_password
  {{- end -}}
{{- end }}

{{/*
Volumes that need to be mounted for .Values.extraConfig entries
*/}}
{{- define "peering-manager.extraConfig.volumes" -}}
{{- range $index, $config := .Values.extraConfig -}}
- name: extra-config-{{ $index }}
  {{- if $config.values }}
  configMap:
    name: {{ include "peering-manager.fullname" $ }}
    items:
      - key: extra-{{ $index }}.yaml
        path: extra-{{ $index }}.yaml
  {{- else if $config.configMap }}
  configMap:
    {{- toYaml $config.configMap | nindent 4 }}
  {{- else if $config.secret }}
  secret:
    {{- toYaml $config.secret | nindent 4 }}
  {{- end }}
{{ end -}}
{{- end }}

{{/*
Volume mounts for .Values.extraConfig entries
*/}}
{{- define "peering-manager.extraConfig.volumeMounts" -}}
{{- range $index, $config := .Values.extraConfig -}}
- name: extra-config-{{ $index }}
  mountPath: /run/config/extra/{{ $index }}
  readOnly: true
{{ end -}}
{{- end }}