{{- define "qbittorrent.workload" -}}
workload:
  qbittorrent:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.qbitNetwork.hostNetwork }}
      containers:
        qbittorrent:
          enabled: true
          primary: true
          imageSelector: image
          {{ with .Values.qbitConfig.additionalEnvs }}
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
              port: 8080
              path: /
            readiness:
              enabled: true
              type: http
              port: 8080
              path: /
            startup:
              enabled: true
              type: http
              port: 8080
              path: /

{{/* Service */}}
service:
  qbittorrent:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: qbittorrent
    ports:
      webui:
        enabled: true
        primary: true
        port: 8080
        nodePort: {{ .Values.qbitNetwork.webPort }}
        targetSelector: qbittorrent
  qbittorrent-bt:
    enabled: true
    type: NodePort
    targetSelector: qbittorrent
    ports:
      bt-tcp:
        enabled: true
        primary: true
        port: {{ .Values.qbitNetwork.btPort }}
        nodePort: {{ .Values.qbitNetwork.btPort }}
        targetSelector: qbittorrent
      bt-upd:
        enabled: true
        primary: true
        port: {{ .Values.qbitNetwork.btPort }}
        nodePort: {{ .Values.qbitNetwork.btPort }}
        protocol: udp
        targetSelector: qbittorrent

{{/* Persistence */}}
persistence:
  config:
    enabled: true
    type: {{ .Values.qbitStorage.config.type }}
    datasetName: {{ .Values.qbitStorage.config.datasetName | default "" }}
    hostPath: {{ .Values.qbitStorage.config.hostPath | default "" }}
    targetSelector:
      qbittorrent:
        qbittorrent:
          mountPath: /config
  {{- range $idx, $storage := .Values.qbitStorage.additionalStorages }}
  {{ printf "qbittorrent-%v" (int $idx) }}:
    enabled: true
    type: {{ $storage.type }}
    datasetName: {{ $storage.datasetName | default "" }}
    hostPath: {{ $storage.hostPath | default "" }}
    targetSelector:
      qbittorrent:
        qbittorrent:
          mountPath: {{ $storage.mountPath }}
  {{- end }}
{{- end -}}
