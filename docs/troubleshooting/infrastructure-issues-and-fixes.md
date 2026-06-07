# Infrastructure Issues and Fixes

## Overview

During the infrastructure provisioning phase, multiple issues were encountered while building the AWS EKS environment using Terraform. This document captures the investigation process, root causes, fixes, and validation steps.

---

# Issue 1: kubectl Connection Timeout

## Error

```text
i/o timeout
```

## Investigation

* Verified EKS cluster status
* Checked route tables
* Checked NAT Gateway
* Verified Security Groups
* Verified cluster endpoint accessibility

## Root Cause

The EKS cluster endpoint was configured with private access only.

## Fix

Enabled both public and private endpoint access:

```hcl
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true
```

## Validation

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-sr-dev-eks
kubectl get namespaces
```

Successfully connected to the cluster.

---

# Issue 2: Authentication Failure

## Error

```text
You must be logged in to the server
```

## Root Cause

Local kubeconfig was not configured for the EKS cluster.

## Fix

Updated kubeconfig:

```bash
aws eks update-kubeconfig --region us-east-1 --name devops-sr-dev-eks
```

## Validation

```bash
kubectl get namespaces
```

Cluster access was restored successfully.

---

# Issue 3: NodeCreationFailure

## Error

```text
Instances failed to join the kubernetes cluster
```

## Investigation

Verified:

* IAM Roles
* Node Group Configuration
* aws-auth ConfigMap
* NAT Gateway
* Route Tables
* Security Groups
* DNS Hostnames
* DNS Support

## Root Cause

Private subnet Network ACL rules blocked required worker node communication.

## Fix

Updated Clouddrove subnet module configuration:

```hcl
private_inbound_acl_rules
private_outbound_acl_rules
```

Configured allow rules for required traffic.

## Validation

Worker nodes were able to communicate with the EKS control plane.

---

# Issue 4: AWS vCPU Quota Exceeded

## Error

```text
VcpuLimitExceeded
```

## Root Cause

Multiple failed EKS node groups remained active and consumed available EC2 vCPU quota.

## Fix

Deleted failed node groups:

```bash
aws eks delete-nodegroup
```

Reduced node group size temporarily during recovery.

## Validation

New node group launched successfully.

---

# Issue 5: Terraform State Drift

## Error

Terraform state contained resources that had already been removed from AWS.

## Root Cause

Manual cleanup operations created a mismatch between AWS resources and Terraform state.

## Fix

Created a state backup:

```bash
terraform state pull > state-backup-before-nodegroup-rm.json
```

Removed stale state entries:

```bash
terraform state rm aws_eks_node_group
terraform state rm aws_launch_template
```

## Validation

Terraform plan and apply completed successfully.

---

# Final Validation

## Terraform

```bash
terraform apply
```

Result:

```text
Apply complete!
```

## EKS Node Status

```bash
kubectl get nodes
```

Result:

```text
STATUS = Ready
```

## Kubernetes System Pods

```bash
kubectl get pods -A
```

Result:

* aws-node Running
* coredns Running
* kube-proxy Running

---

# Key Learnings

* Importance of validating VPC networking and NACL rules
* EKS worker node troubleshooting methodology
* AWS quota management and cleanup procedures
* Terraform state management and recovery techniques
* Systematic debugging of cloud infrastructure issues

```
```
