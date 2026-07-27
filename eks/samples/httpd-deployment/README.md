# HTTPD Sample Application Deployment on EKS

This guide will help you deploy a sample Apache HTTPD web server application to your EKS cluster to verify it's working properly.

## Installation & Setup Guide

### Step 1: Install kubectl

kubectl is the command-line tool for interacting with Kubernetes clusters. Follow the instructions for your operating system:

#### Windows

**Option A: Using Chocolatey (Recommended)**

```powershell
# Install Chocolatey if not already installed
# Run PowerShell as Administrator, then:

choco install kubernetes-cli
```

**Option B: Manual Installation**

1. Download the kubectl binary from [Kubernetes releases page](https://dl.k8s.io/release/stable.txt)
2. Visit: https://dl.k8s.io/release/v1.34.0/bin/windows/amd64/kubectl.exe
3. Save to a folder (e.g., `C:\kubectl\`)
4. Add the folder to your PATH:
   - Right-click "This PC" → Properties
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Add your folder to the PATH variable
5. Restart PowerShell and verify:
   ```powershell
   kubectl version --client
   ```

**Option C: Using WSL2 (Windows Subsystem for Linux)**

If you have WSL2 installed, use Linux installation steps within WSL2.

#### macOS

**Option A: Using Homebrew (Recommended)**

```bash
brew install kubectl
```

**Option B: Using MacPorts**

```bash
sudo port selfupdate
sudo port install kubectl
```

**Option C: Manual Installation**

```bash
# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"

# Make it executable
chmod +x ./kubectl

# Move to PATH
sudo mv ./kubectl /usr/local/bin/kubectl
```

#### Linux (Ubuntu/Debian)

```bash
# Update package index
sudo apt-get update

# Install kubectl
sudo apt-get install -y kubectl

# Or install from Google Cloud repo (official method)
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubectl
```

#### Linux (CentOS/RHEL)

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
EOF

sudo yum install -y kubectl
```

**Verify Installation**

```bash
kubectl version --client
```

You should see output like:
```
Client Version: v1.34.0
Kustomize Version: v5.0.0
```

### Step 2: Install AWS CLI

The AWS CLI is needed to configure kubectl to connect to your EKS cluster.

#### Windows

**Option A: Using Chocolatey**

```powershell
choco install awscli
```

**Option B: Using MSI Installer**

1. Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
2. Run the installer
3. Restart PowerShell

#### macOS

```bash
# Using Homebrew
brew install awscli

# Or download directly
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

#### Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify Installation**

```bash
aws --version
```

### Step 3: Configure AWS Credentials

Before you can use kubectl with EKS, you need to configure AWS credentials.

#### Option A: AWS CLI Configuration (Recommended)

```bash
aws configure
```

You'll be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1`
- Default output format: `json`

**Get your credentials from AWS:**
1. Go to AWS Management Console
2. Click on your username (top-right)
3. Select "Security Credentials"
4. Under "Access keys", click "Create access key"
5. Copy the Access Key ID and Secret Access Key

#### Option B: Environment Variables

```bash
# Linux/macOS
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1

# Windows PowerShell
$env:AWS_ACCESS_KEY_ID = "your_access_key"
$env:AWS_SECRET_ACCESS_KEY = "your_secret_key"
$env:AWS_DEFAULT_REGION = "us-east-1"
```

#### Option C: AWS Config File

Create `~/.aws/config` and `~/.aws/credentials`:

**~/.aws/config**
```
[default]
region = us-east-1
output = json
```

**~/.aws/credentials**
```
[default]
aws_access_key_id = your_access_key
aws_secret_access_key = your_secret_key
```

**Verify AWS Configuration**

```bash
aws sts get-caller-identity
```

Should return your AWS account ID and ARN.

### Step 4: Configure kubectl for EKS

Now that you have kubectl and AWS credentials, configure kubectl to connect to your EKS cluster.

**Run this command:**

```bash
aws eks update-kubeconfig --name lwplabs-cluster --region us-east-1
```

This command:
- Retrieves EKS cluster information from AWS
- Creates/updates your kubeconfig file (usually at `~/.kube/config`)
- Sets up context and credentials for the cluster

**Verify the kubeconfig:**

```bash
# Check kubeconfig location
kubectl config view

# Should show your EKS cluster context
```

### Step 5: Verify Cluster Connection

Test that kubectl is properly configured to access your EKS cluster:

```bash
# Check cluster info
kubectl cluster-info
```

Expected output:
```
Kubernetes control plane is running at https://XXXXXXX.eks.us-east-1.amazonaws.com
CoreDNS is running at https://XXXXXXX.eks.us-east-1.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

**Check nodes:**

```bash
kubectl get nodes
```

Expected output:
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-20-3-xxx.ec2.internal   Ready    <none>   5m    v1.34.0
ip-10-20-4-xxx.ec2.internal   Ready    <none>   5m    v1.34.0
```

If you see 2 nodes with status `Ready`, your cluster is properly configured!

**Get more details:**

```bash
kubectl get nodes -o wide
kubectl describe nodes
```

### Step 6: Verify Connectivity to Private Subnets

Since your EKS cluster uses private subnets, verify the networking is set up correctly:

```bash
# Check cluster subnets
kubectl describe service kubernetes -n default

# Check node IPs are in private subnet range (10.20.3.0/24 or 10.20.4.0/24)
kubectl get nodes -o wide
```

### Step 7: Troubleshooting Installation

**Issue: "kubectl: command not found"**
- Solution: kubectl is not in your PATH. Re-install or add installation directory to PATH.

**Issue: "Unable to connect to the server: dial tcp: lookup <cluster>: no such host"**
- Solution: AWS CLI not configured. Run `aws configure` with correct credentials.

**Issue: "Unable to connect to the server: x509: certificate signed by unknown authority"**
- Solution: kubeconfig is outdated. Run: `aws eks update-kubeconfig --name lwplabs-cluster --region us-east-1`

**Issue: "error: You must be logged in to the server (Unauthorized)"**
- Solution: AWS credentials are invalid or expired. Update AWS credentials and re-run the update-kubeconfig command.

**Test connectivity step-by-step:**

```bash
# 1. Test AWS CLI
aws sts get-caller-identity

# 2. Test EKS cluster exists
aws eks describe-cluster --name lwplabs-cluster --region us-east-1

# 3. Test kubectl connection
kubectl cluster-info

# 4. Test node access
kubectl get nodes

# 5. Test pod access
kubectl get pods --all-namespaces
```

---

## Prerequisites

Before deploying, ensure you have completed all installation steps above. You should have:

1. ✓ **kubectl** installed and verified
2. ✓ **AWS CLI** installed and configured
3. ✓ **AWS Credentials** configured with EKS access
4. ✓ **kubeconfig** file created and tested
5. ✓ **EKS cluster** (lwplabs-cluster) running and accessible
6. ✓ **Nodes** showing as `Ready` in `kubectl get nodes`

### Test Your Setup

Before proceeding with deployment, run this test:

```bash
# Should show your EKS cluster
kubectl cluster-info

# Should show 2 nodes in Ready state
kubectl get nodes

# Should work without errors
kubectl get pods --all-namespaces
```

If all commands succeed, you're ready to deploy the HTTPD application!



## Deployment Steps

### 1. Create a Namespace (Optional but Recommended)

```bash
kubectl create namespace httpd-demo
```

### 2. Deploy the HTTPD Application

Deploy using the provided manifest:

```bash
kubectl apply -f deployment.yaml
```

Or if you created a namespace:

```bash
kubectl apply -f deployment.yaml -n httpd-demo
```

### 3. Verify the Deployment

Check if the deployment was successful:

```bash
# Check deployment status
kubectl get deployments

# Check pods
kubectl get pods

# Check pod details
kubectl describe pod <pod-name>

# View pod logs
kubectl logs <pod-name>
```

### 4. Expose the Application

The deployment includes a service. Check the service status:

```bash
kubectl get svc
```

To access the application:

**Option A: Port Forward (Quick Testing)**

```bash
kubectl port-forward svc/httpd-service 8080:80
```

Then open your browser and visit: `http://localhost:8080`

**Option B: LoadBalancer (Production)**

The service is configured as `ClusterIP`. To expose it via AWS Load Balancer:

```bash
kubectl patch svc httpd-service -p '{"spec":{"type":"LoadBalancer"}}'
```

Wait a few moments for the Load Balancer to be created:

```bash
kubectl get svc httpd-service
```

The external IP will appear under `EXTERNAL-IP`. Copy that IP and access: `http://<EXTERNAL-IP>`

**Option C: Ingress (If you have Ingress Controller)**

If you plan to use an Ingress controller, update the `ingress.yaml` manifest with your domain and apply it.

## Manifest Overview

### deployment.yaml

This file contains:

- **Deployment**: 3 replicas of HTTPD pods
- **Service**: ClusterIP service to expose the application internally
- **ConfigMap**: Custom HTML content to display when accessing the service

### What Gets Deployed

1. **3 HTTPD Pods** - Running Apache HTTP Server
2. **Service** - Internal endpoint to access the pods
3. **ConfigMap** - Custom welcome page

## Testing the Deployment

Once you have the service exposed, you should see:

```html
Welcome to Apache HTTP Server!
Running on EKS cluster: lwplabs-cluster
Pod name: <pod-name>
```

This confirms:
- ✅ EKS cluster is running
- ✅ Nodes can launch pods
- ✅ Pods can run containers
- ✅ Services can route traffic
- ✅ Persistent storage and networking are working

## Cleanup

To remove the deployment and free up resources:

```bash
# Delete using the manifest
kubectl delete -f deployment.yaml

# Or if using a namespace
kubectl delete namespace httpd-demo

# Verify deletion
kubectl get deployments
kubectl get pods
kubectl get svc
```

## Troubleshooting

### Pods not starting?

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Service not getting an External IP?

```bash
kubectl describe svc httpd-service
```

### Can't connect to the service?

1. Verify pods are running: `kubectl get pods`
2. Check service endpoints: `kubectl get endpoints`
3. Test within the cluster:
   ```bash
   kubectl run -it --image=curlimages/curl --restart=Never -- curl http://httpd-service
   ```

### Load Balancer pending?

AWS Load Balancers can take 1-2 minutes to provision. Check status:

```bash
kubectl get svc httpd-service -w
```

## Next Steps

Once this is working, you can:

1. Try deploying other containerized applications
2. Set up persistent storage
3. Configure autoscaling
4. Set up monitoring and logging
5. Deploy a proper ingress controller (e.g., AWS Load Balancer Controller via Helm)

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
