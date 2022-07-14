{{- define "determined.secretPath" -}}
/mount/determined/secrets/
{{- end -}}

{{- define "determined.masterPort" -}}
8081
{{- end -}}

{{- define "determined.region" -}}
{{- if .Values.region }}
{{ .Values.region }}
{{- else }}
{{- default "ORD1" .Values.region }}
{{- end -}}

{{- define "determined.storageSize" -}}
{{- if .Values.db.storageSize }}
{{ .Values.db.storageSize }}
{{- else }}
{{- default "100Gi" .Values.db.storageSize }}
{{- end -}}
{{- end -}}

{{- define "determined.cpuPodSpec" -}}
spec:
    containers:
    - name: determined-cpu-container
        resources:
            requests:
                {{- if .Values.resources.memory }}
                memory: {{ .Values.resources.memory }}
                {{- else }}
                {{- default "32Gi" .Values.resources.memory }}
                {{- end }}
                {{- if .Values.resources.cpu }}
                cpu: {{ .Values.resources.cpu }}
                {{- else }}
                {{- default "8" .Values.resources.cpu }}
                {{- end }}
            limits:
                {{- if .Values.resources.memory }}
                memory: {{ .Values.resources.memory }}
                {{- else }}
                {{- default "32Gi" .Values.resources.memory }}
                {{- end }}
                {{- if .Values.resources.cpu }}
                cpu: {{ .Values.resources.cpu }}
                {{- else }}
                {{- default "8" .Values.resources.cpu }}
                {{- end }}
{{- end -}}

{{- define "determined.gpuType" -}}
{{- if .Values.resources.gpu_type }}
{{ .Values.resources.gpu_type }}
{{- else }}
{{- default "RTX_A5000" .Values.resources.gpu_type }}
{{- end -}}
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
                {{- if .Values.resources.memory }}
                memory: {{ .Values.resources.memory }}
                {{- else }}
                {{- default "32Gi" .Values.resources.memory }}
                {{- end }}
                {{- if .Values.resources.cpu }}
                cpu: {{ .Values.resources.cpu }}
                {{- else }}
                {{- default "8" .Values.resources.cpu }}
                {{- end }}
            limits:
                {{- if .Values.resources.memory }}
                memory: {{ .Values.resources.memory }}
                {{- else }}
                {{- default "32Gi" .Values.resources.memory }}
                {{- end }}
                {{- if .Values.resources.cpu }}
                cpu: {{ .Values.resources.cpu }}
                {{- else }}
                {{- default "8" .Values.resources.cpu }}
                {{- end }}
{{- end -}}