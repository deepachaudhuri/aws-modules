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

## What These Samples Test

By deploying these samples, you verify:

✓ EKS cluster is running and accessible  
✓ Worker nodes are healthy and can schedule pods  
✓ Container images can be pulled and executed  
✓ Kubernetes DNS is working  
✓ Pod networking is configured correctly  
✓ Service discovery works  
✓ Probes (liveness/readiness) are functional  

## Prerequisites

Before deploying any samples, ensure:

1. **kubectl** is installed
2. **kubeconfig** is configured for your EKS cluster
3. EKS cluster (lwplabs-cluster) is running

### Configure kubeconfig

```bash
aws eks update-kubeconfig --name lwplabs-cluster --region us-east-1
```

Verify connection:

```bash
kubectl cluster-info
kubectl get nodes
```

## Deployment Patterns

### Pattern 1: ClusterIP Service (Internal)
```bash
kubectl apply -f deployment.yaml
kubectl port-forward svc/httpd-service 8080:80
# Access via: http://localhost:8080
```

### Pattern 2: LoadBalancer Service (External)
```bash
kubectl apply -f deployment.yaml
kubectl patch svc httpd-service -p '{"spec":{"type":"LoadBalancer"}}'
kubectl get svc httpd-service -w
# Access via the External IP
```

### Pattern 3: Using Port Forward
```bash
kubectl apply -f deployment.yaml
kubectl port-forward svc/httpd-service 8080:80
# Access via: http://localhost:8080
# Ctrl+C to stop
```

## Monitoring & Debugging

### View Deployment Status
```bash
kubectl get deployment httpd
kubectl get pods -l app=httpd
kubectl get svc httpd-service
```

### View Logs
```bash
kubectl logs -l app=httpd --all-containers=true
kubectl logs -f <pod-name>  # Follow logs
```

### Debug Connectivity
```bash
# Test from within cluster
kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://httpd-service/

# Test from specific pod
kubectl exec <pod-name> -- curl http://localhost:80
```

### View Resource Usage
```bash
kubectl top nodes
kubectl top pods
```

## Cleanup

To remove all sample deployments:

```bash
# Delete specific deployment
kubectl delete -f httpd-deployment/deployment.yaml

# Delete entire namespace
kubectl delete namespace httpd-demo

# Verify cleanup
kubectl get deployments
kubectl get pods
kubectl get svc
```

## Troubleshooting

### Pods not starting?
```bash
# Check pod status
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Check node capacity
kubectl describe nodes
```

### Service not accessible?
```bash
# Verify endpoints
kubectl get endpoints httpd-service

# Verify labels match
kubectl get pods --show-labels
```

### Image pull errors?
```bash
# Check node internet connectivity
kubectl exec <pod-name> -- curl -I https://hub.docker.com

# Check pod events
kubectl describe pod <pod-name>
```

## Next Steps

After verifying the samples work:

1. **Deploy Your Own Application**
   - Containerize your application
   - Push to ECR (Elastic Container Registry)
   - Update deployment.yaml with your image

2. **Set Up Persistence**
   - Add PersistentVolumeClaims
   - Use EBS or EFS volumes

3. **Configure Ingress**
   - Set up an Ingress Controller
   - Configure hostname-based routing

4. **Implement Autoscaling**
   - Horizontal Pod Autoscaling (HPA)
   - Cluster Autoscaling

5. **Add Monitoring**
   - Install Prometheus
   - Set up Grafana dashboards
   - Use CloudWatch Container Insights

6. **Implement CI/CD**
   - GitOps with ArgoCD
   - GitHub Actions or Jenkins
   - Automated deployments

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Docker Documentation](https://docs.docker.com/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [AWS Best Practices for EKS](https://docs.aws.amazon.com/eks/latest/userguide/best-practices.html)

## Support

For issues or questions:

1. Check the sample's README
2. Review [COMMANDS.md](httpd-deployment/COMMANDS.md) for kubectl commands
3. Check [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
4. Review Kubernetes documentation
