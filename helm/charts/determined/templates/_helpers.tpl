{{- define "determined.secretPath" -}}
/mount/determined/secrets/
{{- end -}}

{{- define "determined.masterPort" -}}
8081
{{- end -}}

{{- define "determined.region" -}}
{{ .Values.region | default "ORD1" }}
{{- end -}}

{{- define "determined.cpuPodSpec" -}}
spec:
    containers:
    - name: determined-cpu-container
        resources:
            requests:
                memory: {{ .Values.resources.memory  | default "32Gi" }}
                cpu: {{ .Values.resources.cpu | default "8" }}
            limits:
                memory: {{ .Values.resources.memory | default "32Gi" }}
                cpu: {{ .Values.resources.cpu | default "8" }}
{{- end -}}

{{- define "determined.gpuType" -}}
{{ .Values.resources.gpu_type | default "RTX_A5000" }}
{{- end -}}

{{- define "determined.gpuPodSpec" -}}
spec:
    affinity:
    nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
            - matchExpressions:
            - key: topology.kubernetes.io/region
                operator: In
                values:
                - {{ include "determined.region" . }}
            - key: gpu.nvidia.com/class
                operator: In
                values:
                - {{ include "determined.gpuType" . }}
    containers:
    - name: determined-gpu-container
        resources:
            requests:
                memory: {{ .Values.resources.memory  | default "32Gi" }}
                cpu: {{ .Values.resources.cpu | default "8" }}
            limits:
                memory: {{ .Values.resources.memory | default "32Gi" }}
                cpu: {{ .Values.resources.cpu | default "8" }}
{{- end -}}