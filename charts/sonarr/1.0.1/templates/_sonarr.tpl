{{- define "sonarr.workload" -}}
workload:
  sonarr:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.sonarrNetwork.hostNetwork }}
      containers:
        sonarr:
          enabled: true
          primary: true
          imageSelector: image
          {{ with .Values.sonarrConfig.additionalEnvs }}
          envList:
            {{ range $env := . }}
            - name: {{ $env.name }}
              value: {{ $env.value }}
            {{ end }}
          {{ end }}
          probes:
            liveness:
              enabled: true
              type: http
              port: 8989
              path: /ping
            readiness:
              enabled: true
              type: http
              port: 8989
              path: /ping
            startup:
              enabled: true
              type: http
              port: 8989
              path: /ping


{{/* Service */}}
service:
  sonarr:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: sonarr
    ports:
      webui:
        enabled: true
        primary: true
        port: 8989
        nodePort: {{ .Values.sonarrNetwork.webPort }}
        targetSelector: sonarr

{{/* Persistence */}}
persistence:
  config:
    enabled: true
    type: {{ .Values.sonarrStorage.config.type }}
    datasetName: {{ .Values.sonarrStorage.config.datasetName | default "" }}
    hostPath: {{ .Values.sonarrStorage.config.hostPath | default "" }}
    targetSelector:
      sonarr:
        sonarr:
          mountPath: /config

  tmp:
    enabled: true
    type: emptyDir
    targetSelector:
      sonarr:
        sonarr:
          mountPath: /tmp
  {{- range $idx, $storage := .Values.sonarrStorage.additionalStorages }}
  {{ printf "sonarr-%v" (int $idx) }}:
    enabled: true
    type: {{ $storage.type }}
    datasetName: {{ $storage.datasetName | default "" }}
    hostPath: {{ $storage.hostPath | default "" }}
    targetSelector:
      sonarr:
        sonarr:
          mountPath: {{ $storage.mountPath }}
  {{- end }}
{{- end -}}
