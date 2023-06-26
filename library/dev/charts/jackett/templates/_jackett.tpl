{{- define "jackett.workload" -}}
workload:
  jackett:
    enabled: true
    primary: true
    type: Deployment
    podSpec:
      hostNetwork: {{ .Values.jackettNetwork.hostNetwork }}
      containers:
        jackett:
          enabled: true
          primary: true
          imageSelector: image
          {{ with .Values.jackettConfig.additionalEnvs }}
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
              port: 9117
              path: /UI/Login
            readiness:
              enabled: true
              type: http
              port: 9117
              path: /UI/Login
            startup:
              enabled: true
              type: http
              port: 9117
              path: /UI/Login

{{/* Service */}}
service:
  jackett:
    enabled: true
    primary: true
    type: NodePort
    targetSelector: jackett
    ports:
      webui:
        enabled: true
        primary: true
        port: 9117
        nodePort: {{ .Values.jackettNetwork.webPort }}
        targetSelector: jackett

{{/* Persistence */}}
persistence:
  config:
    enabled: true
    type: {{ .Values.jackettStorage.config.type }}
    datasetName: {{ .Values.jackettStorage.config.datasetName | default "" }}
    hostPath: {{ .Values.jackettStorage.config.hostPath | default "" }}
    targetSelector:
      jackett:
        jackett:
          mountPath: /config
  tmp:
    enabled: true
    type: emptyDir
    targetSelector:
      jackett:
        jackett:
          mountPath: /tmp
  {{- range $idx, $storage := .Values.jackettStorage.additionalStorages }}
  {{ printf "jackett-%v" (int $idx) }}:
    enabled: true
    type: {{ $storage.type }}
    datasetName: {{ $storage.datasetName | default "" }}
    hostPath: {{ $storage.hostPath | default "" }}
    targetSelector:
      jackett:
        jackett:
          mountPath: {{ $storage.mountPath }}
  {{- end }}
{{- end -}}
