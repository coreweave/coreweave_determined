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
    - name: determined-cpu-container
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
                    - {{ .Values.region }}
                - key: gpu.nvidia.com/class
                    operator: In
                    values:
                    - {{ .Values.resources.gpu_type }}
    containers:
    - name: determined-gpu-container
        resources:
            requests:
                memory: {{ .Values.resources.memory }}
                cpu: {{ .Values.resources.cpu }}
            limits:
                memory: {{ .Values.resources.memory }}
                cpu: {{ .Values.resources.cpu }}
{{- end -}}