{{- define "bazarr.workload" -}}
workload:
  bazarr:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.bazarrNetwork.hostNetwork }}
      containers:
        bazarr:
          enabled: true
          primary: true
          imageSelector: image
          {{ with .Values.bazarrConfig.additionalEnvs }}
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
              port: 6767
              path: /ping
            readiness:
              enabled: true
              type: http
              port: 6767
              path: /ping
            startup:
              enabled: true
              type: http
              port: 6767
              path: /ping


{{/* Service */}}
service:
  bazarr:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: bazarr
    ports:
      webui:
        enabled: true
        primary: true
        port: 6767
        nodePort: {{ .Values.bazarrNetwork.webPort }}
        targetSelector: bazarr

{{/* Persistence */}}
persistence:
  config:
    enabled: true
    type: {{ .Values.bazarrStorage.config.type }}
    datasetName: {{ .Values.bazarrStorage.config.datasetName | default "" }}
    hostPath: {{ .Values.bazarrStorage.config.hostPath | default "" }}
    targetSelector:
      bazarr:
        bazarr:
          mountPath: /config

  tmp:
    enabled: true
    type: emptyDir
    targetSelector:
      bazarr:
        bazarr:
          mountPath: /tmp
  {{- range $idx, $storage := .Values.bazarrStorage.additionalStorages }}
  {{ printf "bazarr-%v" (int $idx) }}:
    enabled: true
    type: {{ $storage.type }}
    datasetName: {{ $storage.datasetName | default "" }}
    hostPath: {{ $storage.hostPath | default "" }}
    targetSelector:
      bazarr:
        bazarr:
          mountPath: {{ $storage.mountPath }}
  {{- end }}
{{- end -}}
