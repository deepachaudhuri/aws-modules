# EKS Module

This module creates a production-ready Amazon EKS (Elastic Kubernetes Service) cluster with support for multiple add-ons and IAM Roles for Service Accounts (IRSA).

## Table of Contents

- [Prerequisites](#prerequisites)
- [EKS Cluster Overview](#eks-cluster-overview)
- [Add-ons](#add-ons)
- [IRSA - IAM Roles for Service Accounts](#irsa---iam-roles-for-service-accounts)
- [Usage](#usage)
- [Kubernetes Step-by-Step Learning](#kubernetes-step-by-step-learning)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- AWS account with appropriate IAM permissions
- Terraform >= 1.5.0
- kubectl configured with AWS credentials
- VPC and subnets already created (use the VPC module)

## EKS Cluster Overview

Amazon EKS is a managed Kubernetes service on AWS. This module sets up:

- **Control Plane**: AWS-managed Kubernetes control plane
- **Worker Nodes**: EC2 instances running Kubernetes workloads
- **OIDC Provider**: Enables IRSA for fine-grained IAM permissions
- **Add-ons**: Pre-configured AWS extensions for EKS

### What is IRSA?

**IRSA (IAM Roles for Service Accounts)** allows Kubernetes service accounts to assume AWS IAM roles. This means:

- Your pods can have AWS permissions without storing credentials
- Pods only get the minimal permissions they need
- Credentials are temporary and auto-rotating

### IRSA Flow

```
Pod (running container) 
  ↓
Kubernetes Service Account
  ↓
OIDC Provider (IRSA)
  ↓
AWS IAM Role
  ↓
AWS Service Permissions (S3, DynamoDB, etc.)
```

## Add-ons

This module supports the following AWS add-ons:

### 1. AWS Load Balancer Controller
- **Purpose**: Automatically provision AWS ALB/NLB for Kubernetes Ingress resources
- **Default**: Enabled
- **IRSA Role**: `aws_load_balancer_controller` service account

```yaml
# Example: Use AWS Load Balancer Controller
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
```

### 2. EBS CSI Driver
- **Purpose**: Dynamically provision EBS volumes for Kubernetes PersistentVolumes
- **Default**: Enabled
- **IRSA Role**: `ebs-csi-controller-sa` service account

```yaml
# Example: Use EBS volumes
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 10Gi
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
```

### 3. EFS CSI Driver
- **Purpose**: Mount EFS (NFS) volumes for shared storage across pods
- **Default**: Enabled
- **IRSA Role**: `efs-csi-controller-sa` service account

```yaml
# Example: Use EFS volumes
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 10Gi
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
```

### 4. CloudWatch Container Insights
- **Purpose**: Monitor EKS cluster and pod performance
- **Default**: Enabled
- **IRSA Role**: `cloudwatch-agent` service account

```bash
# View CloudWatch metrics in AWS Console:
# CloudWatch > Container Insights > Cluster Monitoring
```

## IRSA - IAM Roles for Service Accounts

### How IRSA Works

1. **Pod** requests temporary AWS credentials
2. **Webhook** intercepts the request and injects the service account token
3. **OIDC Provider** validates the token
4. **STS AssumeRole** exchanges token for AWS credentials
5. **AWS API** receives the request with pod's IAM role

### Creating Custom IRSA Roles

To create your own service account with AWS permissions:

```hcl
# In your Terraform code:

# 1. Get the OIDC Provider info from EKS module output
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_iam_openid_connect_provider" "oidc" {
  arn = module.eks.oidc_provider_arn
}

# 2. Create an IAM role that trusts the OIDC provider
resource "aws_iam_role" "my_app_role" {
  name = "my-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub" = "system:serviceaccount:default:my-app"
          }
        }
      }
    ]
  })
}

# 3. Attach permissions to the role
resource "aws_iam_role_policy" "my_app_policy" {
  name = "my-app-policy"
  role = aws_iam_role.my_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::my-bucket/*"
      }
    ]
  })
}
```

Then create the Kubernetes service account:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/my-app-role
```

## Usage

### Basic Example

```hcl
module "eks" {
  source = "git::https://github.com/deepachaudhuri/aws-modules.git//eks?ref=master"

  cluster_name       = "my-cluster"
  kubernetes_version = "1.34"  # Latest EKS version
  subnet_ids         = module.vpc.private_subnet_ids

  node_groups = [
    {
      name           = "general"
      subnet_ids     = module.vpc.private_subnet_ids
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]
      disk_size      = 20
    }
  ]

  enable_aws_load_balancer_controller = true
  enable_ebs_csi_driver               = true
  enable_efs_csi_driver               = true
  enable_cloudwatch_observability     = true

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### Get Kubeconfig

```bash
aws eks update-kubeconfig --region us-east-1 --name my-cluster
```

## Kubernetes Step-by-Step Learning

### Step 1: Verify Cluster Connection

```bash
# Check cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# Describe node (see resources)
kubectl describe node <node-name>
```

### Step 2: Deploy a Simple Pod

```yaml
# nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

```bash
# Apply the pod
kubectl apply -f nginx-pod.yaml

# Check pod status
kubectl get pods

# View pod logs
kubectl logs nginx-pod

# Exec into pod
kubectl exec -it nginx-pod -- /bin/bash
```

### Step 3: Create a Deployment (Replicated Pods)

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
```

```bash
# Deploy
kubectl apply -f nginx-deployment.yaml

# Check deployments
kubectl get deployments

# Check pods (notice replicas)
kubectl get pods -o wide

# Scale deployment
kubectl scale deployment nginx-deployment --replicas=5

# Check rollout status
kubectl rollout status deployment/nginx-deployment
```

### Step 4: Expose with a Service

```yaml
# nginx-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  type: LoadBalancer
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

```bash
# Create service
kubectl apply -f nginx-service.yaml

# Check service
kubectl get svc

# Get external IP (may take a minute)
kubectl get svc nginx-service --watch
```

### Step 5: Use Storage (EBS)

```yaml
# storage-example.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-ebs
spec:
  containers:
  - name: app
    image: nginx:latest
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: ebs-pvc
```

```bash
# Check PVC status
kubectl get pvc

# Check PV (automatically created by EBS CSI Driver)
kubectl get pv
```

### Step 6: Use IRSA to Access AWS Services

```yaml
# irsa-example-service-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-app-sa
  namespace: default
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/my-app-role
---
apiVersion: v1
kind: Pod
metadata:
  name: my-app-pod
spec:
  serviceAccountName: my-app-sa
  containers:
  - name: app
    image: amazon/aws-cli:latest
    command:
    - sleep
    - "3600"
```

```bash
# Exec into pod and test AWS access
kubectl exec -it my-app-pod -- bash

# Inside pod:
aws s3 ls  # Will work if role has S3 permissions
aws dynamodb list-tables  # Will work if role has DynamoDB permissions
```

### Step 7: Use Ingress (AWS Load Balancer)

```yaml
# ingress-example.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-ingress
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx-service
            port:
              number: 80
```

```bash
# Create ingress
kubectl apply -f ingress-example.yaml

# Check ingress
kubectl get ingress

# Get ALB URL
kubectl get ingress my-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 8: Monitor with CloudWatch

```bash
# View container logs in CloudWatch
# AWS Console > CloudWatch > Log Groups > /aws/eks/my-cluster/cluster

# View Container Insights
# AWS Console > CloudWatch > Container Insights > Cluster Monitoring > my-cluster

# View pod performance
kubectl top nodes
kubectl top pods --all-namespaces
```

## Interview Tips

### Key Concepts to Understand

1. **Control Plane** = Kubernetes master (AWS-managed)
2. **Worker Nodes** = EC2 instances running pods
3. **Pods** = Smallest unit, contains containers
4. **Deployments** = Manage pod replicas
5. **Services** = Network abstraction for pods
6. **IRSA** = Fine-grained IAM permissions for pods
7. **Add-ons** = AWS-managed Kubernetes extensions

### Common Interview Questions

1. **What is IRSA and why is it important?**
   - Answer: IRSA allows pods to assume AWS IAM roles, providing secure, temporary credentials without storing keys in pods

2. **Explain the difference between EBS and EFS in Kubernetes**
   - EBS: Block storage, single-attach, good for databases
   - EFS: File storage, multi-attach, good for shared data

3. **How do you give a pod access to S3?**
   - Answer: Create IAM role, create Kubernetes service account with IRSA annotation, attach pod to service account

4. **What's the difference between a Service and an Ingress?**
   - Service: Internal networking, exposes pods
   - Ingress: External networking, routes HTTP/HTTPS to services

## Outputs

The module provides:

- `cluster_id`: EKS cluster name
- `cluster_endpoint`: Kubernetes API endpoint
- `cluster_ca_certificate`: CA certificate for authentication
- `oidc_provider_arn`: OIDC provider ARN (for IRSA)
- `configure_kubectl_command`: Command to set up kubeconfig

## Troubleshooting

### Pod can't access AWS services

```bash
# Check if service account has IRSA annotation
kubectl describe sa my-app-sa

# Check if IAM role trusts the OIDC provider
aws iam get-role --role-name my-app-role

# Inside pod, check assumed role
kubectl exec -it my-app-pod -- aws sts get-caller-identity
```

### Can't connect to cluster

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name my-cluster

# Check kubeconfig
cat ~/.kube/config

# Test connection
kubectl get nodes
```

### EBS/EFS volumes not provisioning

```bash
# Check CSI driver addon status
kubectl get addon -n kube-system

# Check CSI controller logs
kubectl logs -n kube-system -l app=ebs-csi-controller

# Check PVC status
kubectl describe pvc my-pvc
```
