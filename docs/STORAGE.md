# Storage planning (NVMe vs HDD)

## Current assumptions

- **NVME_STORAGE_FAST1** (~300 GB): best for databases and fast scratch (Milvus segments, PostgreSQL, Redis persistence if you move it off emptyDir).
- **HDD_STORAGE_SLOW1** (1 TB, ISOs/backups): avoid heavy random I/O workloads here.
- **Future HDD_STORAGE_1x3TB**: good for large sequential datasets, WORM-style archives, or Milvus cold storage if you tier later.

## Kubernetes

PVCs use whatever **StorageClass** points to (here: `local-path` on node disk). To tie a class to a **Proxmox** datastore:

1. Install a CSI or keep using `local-path` on VMs whose disks live on NVMe.  
2. When the 3 TB disk is added, create a **new** StorageClass (e.g. `hdd-3tb`) with a provisioner that uses that datastore.  
3. **Do not** move existing PVCs blindly; migrate with backup/restore or app-level export.

## Recommendations

| Workload | Preferred tier |
|----------|------------------|
| PostgreSQL (Langfuse) | NVMe / fast |
| Milvus standalone data | NVMe first; large indexes later on HDD if needed |
| Langfuse uploads | Start NVMe; bulk to HDD class when available |
| Model cache (`emptyDir` or PVC) | NVMe for vLLM/SGLang if large models |
