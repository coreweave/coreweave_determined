{{- define "determined.secretPath" -}}
/mount/determined/secrets/
{{- end -}}

{{- define "determined.masterPort" -}}
8081
{{- end -}}

{{- define "determined.cpuPodSpec" -}}
spec:
  priorityClassName: determined-system-priority
  containers:
  - name: determined-container
    resources:
      requests:
        memory: {{ .Values.resources.memory }}
        cpu: {{ .Values.resources.cpu }}
      limits:
        memory: {{ .Values.resources.memory }}
        cpu: {{ .Values.resources.cpu }}
{{- end -}}

{{- define "determined.gpuPodSpec" -}}
spec:
  priorityClassName: determined-system-priority
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
            - key: topology.kubernetes.io/region
              operator: In
              values:
                - {{ .Values.region | upper }}
            - key: gpu.nvidia.com/class
              operator: In
              values:
                - {{ .Values.resources.gpuType }}
  containers:
  - name: determined-container
    resources:
      requests:
        memory: {{ .Values.resources.memory }}
        cpu: {{ .Values.resources.cpu }}
      limits:
        memory: {{ .Values.resources.memory }}
        cpu: {{ .Values.resources.cpu }}
  {{- if gt (len .Values.mounts) 0 }}
    volumeMounts:
      {{- range .Values.mounts }}
      - name: {{ regexReplaceAll "[_]" .pvc "-" | lower }}
        mountPath: {{ .name }}
      {{- end }}
  volumes:
    {{- range .Values.mounts }}
    - name: {{ regexReplaceAll "[_]" .pvc "-" | lower }}
      persistentVolumeClaim:
        claimName: {{ .pvc }}
    {{- end }}
  {{- end -}}
{{- end -}}