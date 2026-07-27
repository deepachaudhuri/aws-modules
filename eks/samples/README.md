# LWPLabs Kubernetes Samples

This directory contains sample applications to help you learn and test your EKS cluster.

## Available Samples

### 1. HTTPD Deployment

A simple Apache HTTP Server application to verify your EKS cluster is working properly.

**Location:** `httpd-deployment/`

**What it includes:**
- Simple HTTPD web server deployment
- ConfigMap with custom HTML content
- Kubernetes Service for internal networking
- Health checks (liveness and readiness probes)
- Resource limits and requests
- Dynamic pod information display

**Quick Start:**

```bash
cd httpd-deployment

# Option 1: Using automated script
# Linux/Mac
bash deploy.sh

# Windows
deploy.bat

# Option 2: Manual deployment
kubectl apply -f deployment.yaml
kubectl port-forward svc/httpd-service 8080:80

# Then visit: http://localhost:8080
```

**Documentation:**
- [HTTPD Deployment README](httpd-deployment/README.md) - Detailed deployment guide
- [Useful Commands](httpd-deployment/COMMANDS.md) - kubectl commands reference

### 2. Nginx Ingress with ALB & Multiple Services (NEW!)

Production-ready setup with Nginx Ingress Controller routing traffic to multiple microservices using AWS ALB.

**Location:** `nginx-ingress-guide.md`

**What it includes:**
- Nginx Ingress Controller installation
- AWS Load Balancer Controller integration
- Multiple microservices (Login, Product services)
- Path-based routing (/login, /product)
- Cost-effective single ALB architecture
- SSL/TLS termination setup

**Key Benefits:**
- ✅ **Cost Efficient**: Single ALB for multiple services (~70% cost savings)
- ✅ **Advanced Routing**: Path-based and host-based routing
- ✅ **Production Ready**: Enterprise-grade load balancing
- ✅ **Easy Management**: Centralized ingress configuration
- ✅ **Scalable**: Add new services without changing infrastructure

**Quick Start:**

```bash
# 1. Install Helm (package manager)
# macOS: brew install helm
# Windows: choco install kubernetes-helm
# Linux: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 2. Install Nginx Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.service.type=LoadBalancer

# 3. Deploy multiple services
kubectl apply -f multi-services/login-service.yaml
kubectl apply -f multi-services/product-service.yaml

# 4. Create Ingress rules
kubectl apply -f multi-services/ingress-rules.yaml

# 5. Get external URL
kubectl get svc -n ingress-nginx

# 6. Access your services
# http://external-ip/login
# http://external-ip/product
```

**Documentation:**
- [Complete Nginx Ingress Guide](nginx-ingress-guide.md) - Full setup instructions
- Architecture diagrams and troubleshooting

---

## What These Samples Test & Teach

### HTTPD Deployment Tests:
✓ EKS cluster is running and accessible  
✓ Worker nodes are healthy and can schedule pods  
✓ Container images can be pulled and executed  
✓ Kubernetes DNS is working  
✓ Pod networking is configured correctly  
✓ Service discovery works  
✓ Probes (liveness/readiness) are functional  

### Nginx Ingress Setup Teaches:
✓ How to install and configure Ingress Controllers  
✓ Path-based routing for microservices  
✓ Integrating AWS ALB with Kubernetes  
✓ Managing multiple services with a single entry point  
✓ Cost optimization strategies  
✓ Production-grade networking patterns  

---

## Prerequisites

Before deploying any samples, ensure:

1. **kubectl** is installed
2. **kubeconfig** is configured for your EKS cluster
3. **Helm** is installed (for Ingress samples)
4. **EKS cluster** (lwplabs-cluster) is running

### Configure kubeconfig

```bash
aws eks update-kubeconfig --name lwplabs-cluster --region us-east-1
```

Verify connection:

```bash
kubectl cluster-info
kubectl get nodes
```

### Install Helm

**macOS:**
```bash
brew install helm
```

**Windows (PowerShell):**
```powershell
choco install kubernetes-helm
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## Deployment Patterns

### Pattern 1: ClusterIP Service with Port Forward (Local Testing)
```bash
kubectl apply -f deployment.yaml
kubectl port-forward svc/httpd-service 8080:80
# Access via: http://localhost:8080
```

### Pattern 2: LoadBalancer Service (Single Service Exposure)
```bash
kubectl apply -f deployment.yaml
kubectl patch svc httpd-service -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc httpd-service -w
# Access via the External IP
```

### Pattern 3: Nginx Ingress (Multiple Services)
```bash
# Install Ingress Controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Deploy services and Ingress rules
kubectl apply -f multi-services/
# Access via single ALB endpoint with path-based routing
```

---

## Cost Comparison

| Architecture | Monthly Cost | Use Case |
|---|---|---|
| Multiple LoadBalancer Services | ~$48 (3 services × $16) | Quick testing, isolated services |
| Single Nginx Ingress + ALB | ~$16 | Production, multiple services |
| **Savings** | **~$32 (67% savings)** | **Multiple microservices** |

---

## Monitoring & Debugging

### View Deployment Status
```bash
kubectl get deployment
kubectl get pods -l app=httpd
kubectl get svc
```

### View Ingress Status
```bash
kubectl get ingress -n services
kubectl describe ingress multi-service-ingress -n services
```

### View Logs
```bash
# Service logs
kubectl logs -l app=httpd --all-containers=true

# Ingress logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f
```

### Debug Connectivity
```bash
# Test from within cluster
kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://httpd-service/

# Test Ingress
kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://login-service.services/
```

---

## Cleanup

### Remove HTTPD Deployment
```bash
kubectl delete -f httpd-deployment/deployment.yaml
```

### Remove Multiple Services
```bash
kubectl delete -f multi-services/
```

### Remove Nginx Ingress
```bash
helm uninstall nginx-ingress -n ingress-nginx
kubectl delete namespace ingress-nginx
```

### Verify Cleanup
```bash
kubectl get deployments
kubectl get pods
kubectl get svc
```

---

## Next Steps

### After Basic Testing (HTTPD):
1. **Deploy Multiple Services** - Try the Nginx Ingress setup
2. **Add SSL/TLS** - Implement certificate management
3. **Enable Monitoring** - Set up Prometheus and Grafana
4. **Implement CI/CD** - Use GitOps with ArgoCD

### After Ingress Setup:
1. **Add Domain Names** - Configure custom domains
2. **Implement WAF** - Use AWS WAF with ALB
3. **Add Authentication** - Use OAuth2 with Ingress
4. **Scale Services** - Implement Horizontal Pod Autoscaling
5. **Add Persistence** - Use EBS or EFS volumes

---

## Learning Path

```
┌─────────────────────────────────────────┐
│ 1. Deploy HTTPD (Basic Testing)         │
│    ├─ Verify cluster is working         │
│    └─ Test pod/service networking       │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 2. Deploy Multiple Services             │
│    ├─ Create Login service              │
│    ├─ Create Product service            │
│    └─ Test individual services          │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 3. Install Nginx Ingress Controller     │
│    ├─ Deploy Ingress pod                │
│    └─ Verify external access            │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 4. Create Ingress Rules                 │
│    ├─ Path-based routing                │
│    ├─ Service discovery                 │
│    └─ Traffic routing                   │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ 5. Configure ALB Integration            │
│    ├─ AWS Load Balancer Controller      │
│    ├─ SSL/TLS setup                     │
│    └─ Advanced routing                  │
└─────────────────────────────────────────┘
```

---

## Troubleshooting

### Pods not starting?
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Service not accessible?
```bash
kubectl get endpoints
kubectl describe svc <service-name>
```

### Ingress not routing traffic?
```bash
kubectl describe ingress <ingress-name>
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### ALB not being created?
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

---

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [AWS Best Practices for EKS](https://docs.aws.amazon.com/eks/latest/userguide/best-practices.html)

---

## Support

For issues or questions:

1. Check the sample's README
2. Review [HTTPD Deployment Commands](httpd-deployment/COMMANDS.md)
3. Read [Nginx Ingress Guide](nginx-ingress-guide.md) troubleshooting section
4. Check [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
5. Review Kubernetes documentation
