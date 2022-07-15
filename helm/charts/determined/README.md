# Determined Helm Chart for CoreWeave

## Pre-Requisistes:

- Retrieve your credentials and access to a VM on CoreWeave. _Please contact CoreWeave support if you are having trouble._
- Download your ```kube_config``` and ensure you can run k8s commands in your namespace on your VM and ensure they succeed.
- Ensure you have S3 credentials. _Please contact CoreWeave support if you are having trouble._ 
- Create a bucket with your S3 credentials. You can use a tool called: ```s3cmd```. You can run it like this: ```s3cmd --config=your-config-location mb s3://<BUCKET_NAME>```.
- Install the determined CLI via: https://docs.determined.ai/latest/interact/cli.html

## Installation

- Deploy the ```determined``` Helm chart via the Application Catalog on CoreWeave cloud. _(Search for it in the Application Catalog)_
- You need to pass in the following fields to enable determined.ai to function properly:

| Helm Chart Config Value  | Description |
| ------------- | ------------- |
| Region | Region where you are deploying determined.  |
| vCPU Request | Default number of vCPUs for your workloads. (default: 8) |
| vCPU Request | Default number of vCPUs for your workloads. (default: 16Gi) |
| GPU Type | Default GPU type for your workloads. We offer a variety of GPUs to choose from. (default: RTX_A5000) |
| Bucket Name (S3) | <BUCKET_NAME> to use for checkpoints you created earlier. |
| Access Key (S3) | Access Key for S3. |
| Secret Key (S3) | Secret Key for S3. |

## Connecting to determined.ai Master

- On your VM, run: ```kubectl get service determined-master-service-<NAME_OF_YOUR_DETERMINED_DEPLOYMENT>``` to retrieve the ```ClusterIP```.
- Run ```export DET_MASTER=<CLUSTER_IP>:8080``` to access the master
- Run ```det experiment list``` and ensure your output looks similar to this:
```
ID   | Owner   | Name   | Parent ID   | State   | Progress   | Start Time   | End Time   | Resource Pool 
------+---------+--------+-------------+---------+------------+--------------+------------+-----------------
```

## Web UI
- You can access the UI from CoreWeave where you launched the deployment. 
- The default username is ```admin``` and the password field is blank. You are welcome to add/edit users and change the password from the CLI.

## Running Experiments

You can start by running any of the [examples](https://docs.determined.ai/latest/examples.html). Below are details on customizing training jobs. 

**IMPORTANT:**

```
# This is the number of GPUs there are per machine. Determined uses this information when scheduling
# multi-GPU tasks. Each multi-GPU (distributed training) task will be scheduled as a set of
# `slotsPerTask / maxSlotsPerPod` separate pods, with each pod assigned up to `maxSlotsPerPod` GPUs.
# Distributed tasks with sizes that are not divisible by `maxSlotsPerPod` are never scheduled. If
# you have a cluster of different size nodes (e.g., 4 and 8 GPUs per node), set `maxSlotsPerPod` to
# the greatest common divisor of all the sizes (4, in that case).
maxSlotsPerPod: 8
```

- In the configuration, ```slotsPerTask``` -> ```slots_per_trial```. Therefore, if you set ```slots_per_trial: 16```, two pods with 8 GPUs each will be spawned for the training workload.

### Running a custom training job

**Example (Running multi-node GPU training):**

_Note the ```slots_per_trial: 16```_

```
name: fashion_mnist_tf_keras_distributed
hyperparameters:
  global_batch_size: 256
  dense1: 128
resources:
  slots_per_trial: 16
records_per_epoch: 600
environment:
searcher:
  name: single
  metric: val_accuracy
  smaller_is_better: false
  max_length:
    epochs: 5
entrypoint: model_def:FashionMNISTTrial
```

**Example (Running multi-node GPU training using custom affinities/region):**

_Note that per-GPU batch size =  ```global_batch_size // slots_per_trial = 16```_

```
name: fashion_mnist_tf_keras_distributed
hyperparameters:
  global_batch_size: 256
  dense1: 128
resources:
  slots_per_trial: 16
records_per_epoch: 600
environment:
  pod_spec:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: gpu.nvidia.com/class
                    operator: In
                    values:
                      - RTX_A5000
                  - key: topology.kubernetes.io/region
                    operator: In
                    values:
                      - ORD1
searcher:
  name: single
  metric: val_accuracy
  smaller_is_better: false
  max_length:
    epochs: 5
entrypoint: model_def:FashionMNISTTrial
```

**Example (Running multi-node GPU training using custom affinities/region and RDMA/Infiniband):**

_Note that per-GPU batch size =  ```global_batch_size // slots_per_trial = 16```_

```
name: fashion_mnist_tf_keras_distributed
hyperparameters:
  global_batch_size: 256
  dense1: 128
resources:
  slots_per_trial: 16
records_per_epoch: 600
environment:
  pod_spec:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: gpu.nvidia.com/class
                    operator: In
                    values:
                      - A100_NVLINK
                  - key: topology.kubernetes.io/region
                    operator: In
                    values:
                      - ORD1
      containers:
        - name: determined-container
          resources:
            limits:
              rdma/ib: '1'
searcher:
  name: single
  metric: val_accuracy
  smaller_is_better: false
  max_length:
    epochs: 5
entrypoint: model_def:FashionMNISTTrial
```

## Mounting a PVC

- This allows you to deploy your training workload on a large amount of data that might be slow to fetch via S3 (network latency).
- This [document](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/) provides all the necessary information required to create a PersistentVolume and PersistentVolumeClaim. 
- Ensure you use the right ```storageClassName```
- You can add your PVC to your ```pod_spec```. Here is an example:

```
name: fashion_mnist_tf_keras_distributed
hyperparameters:
  global_batch_size: 256
  dense1: 128
resources:
  slots_per_trial: 16
records_per_epoch: 600
environment:
  pod_spec:
    spec:
      volumes:
        - name: <VOLUME_NAME>
        persistentVolumeClaim:
          claimName: <PERSISTENT_VOLUME_CLAIM_NAME>
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: gpu.nvidia.com/class
                    operator: In
                    values:
                      - A100_NVLINK
                  - key: topology.kubernetes.io/region
                    operator: In
                    values:
                      - ORD1
      containers:
        volumeMounts:
          - mountPath: "<PATH_TO_MOUNT_TO_INGEST_TRAINING_DATA>"
            name: <VOLUME_NAME>
searcher:
  name: single
  metric: val_accuracy
  smaller_is_better: false
  max_length:
    epochs: 5
entrypoint: model_def:FashionMNISTTrial
```

## Useful Links

- [Distributed Training](https://docs.determined.ai/latest/training-distributed/index.html#multi-gpu-training)
- [Determined Github](https://github.com/determined-ai/determined)
- [Helm Chart Configuration Details](https://docs.determined.ai/latest/sysadmin-deploy-on-k8s/helm-config.html)
- [Determined Training APIS](https://docs.determined.ai/latest/training-apis/index.html)
- [Determined Cluster APIS](https://docs.determined.ai/latest/interact/index.html)



