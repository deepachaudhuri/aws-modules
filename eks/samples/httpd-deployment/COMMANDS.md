# Useful Commands Reference

Quick reference for common kubectl commands and useful operations for testing your EKS cluster.

## Basic Commands

### View Cluster Information
```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes
kubectl get nodes -o wide

# Describe a node
kubectl describe node <node-name>
```

### Deployment Operations

```bash
# List deployments
kubectl get deployments
kubectl get deployments -A  # All namespaces

# Describe deployment
kubectl describe deployment httpd

# View deployment events
kubectl get events -n <namespace>

# Scale deployment
kubectl scale deployment httpd --replicas=5 -n <namespace>

# Update deployment
kubectl set image deployment/httpd httpd=httpd:2.4-slim -n <namespace>

# Rollback deployment
kubectl rollout history deployment/httpd -n <namespace>
kubectl rollout undo deployment/httpd -n <namespace>
```

### Pod Operations

```bash
# List pods
kubectl get pods
kubectl get pods -n <namespace>
kubectl get pods -o wide  # More details
kubectl get pods -l app=httpd  # Filter by label

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# View pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs -l app=httpd -n <namespace>  # Logs from all pods with label
kubectl logs <pod-name> -n <namespace> --tail=50  # Last 50 lines
kubectl logs <pod-name> -n <namespace> -f  # Follow logs

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh

# Copy files from pod
kubectl cp <pod-name>:/path/to/file ./local-file -n <namespace>

# Port forward to pod
kubectl port-forward <pod-name> 8080:80 -n <namespace>
```

### Service Operations

```bash
# List services
kubectl get svc
kubectl get svc -n <namespace>

# Describe service
kubectl describe svc httpd-service -n <namespace>

# View endpoints
kubectl get endpoints
kubectl get endpoints httpd-service -n <namespace>

# Change service type
kubectl patch svc httpd-service -p '{"spec":{"type":"LoadBalancer"}}' -n <namespace>

# Port forward to service
kubectl port-forward svc/httpd-service 8080:80 -n <namespace>
```

### Namespace Operations

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace <namespace-name>

# Delete namespace
kubectl delete namespace <namespace-name>

# Set default namespace
kubectl config set-context --current --namespace=<namespace-name>
```

### ConfigMap & Secrets

```bash
# List ConfigMaps
kubectl get configmaps -n <namespace>

# View ConfigMap
kubectl describe configmap httpd-config -n <namespace>
kubectl get configmap httpd-config -o yaml -n <namespace>

# View ConfigMap data
kubectl get configmap httpd-config -o jsonpath='{.data.index\.html}' -n <namespace>
```

## Troubleshooting Commands

### Pod Issues

```bash
# Check pod status details
kubectl describe pod <pod-name> -n <namespace>

# View recent events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check if pod is running
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.status.phase}'

# View all containers in pod
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[*].name}'
```

### Network Testing

```bash
# Test DNS from within cluster
kubectl run -it --image=busybox --restart=Never --rm -- nslookup httpd-service.<namespace>

# Test connectivity to service
kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://httpd-service/

# Test from specific pod
kubectl exec <pod-name> -n <namespace> -- curl http://localhost:80
```

### Resource Usage

```bash
# View resource usage
kubectl top nodes
kubectl top pods -n <namespace>

# View resource requests/limits
kubectl describe pod <pod-name> -n <namespace> | grep -A 3 "Limits\|Requests"
```

## Quick Testing Script

```bash
#!/bin/bash
NAMESPACE="httpd-demo"

echo "=== Deployment Status ==="
kubectl get deployment httpd -n $NAMESPACE

echo -e "\n=== Pod Status ==="
kubectl get pods -n $NAMESPACE

echo -e "\n=== Service Status ==="
kubectl get svc httpd-service -n $NAMESPACE

echo -e "\n=== Testing Service Connectivity ==="
kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://httpd-service.$NAMESPACE/

echo -e "\n=== Pod Logs ==="
kubectl logs -l app=httpd -n $NAMESPACE --tail=5
```

## Useful Aliases

Add these to your `.bashrc` or `.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgd='kubectl get deployment'
alias kgs='kubectl get svc'
alias kdp='kubectl describe pod'
alias kdd='kubectl describe deployment'
alias kds='kubectl describe svc'
alias kl='kubectl logs'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
```

## Common Issues & Quick Fixes

### Pods stuck in Pending
```bash
# Check node capacity and resource requests
kubectl describe nodes
kubectl describe pod <pod-name> -n <namespace>

# Check node affinity rules
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 10 affinity
```

### Service not accessible
```bash
# Verify endpoints are created
kubectl get endpoints httpd-service -n <namespace>

# Check service selector
kubectl describe svc httpd-service -n <namespace> | grep Selector

# Verify labels on pods
kubectl get pods --show-labels -n <namespace>
```

### Pod logs show errors
```bash
# Check previous logs (if pod restarted)
kubectl logs <pod-name> -n <namespace> --previous

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check probe failures
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 5 -E "livenessProbe|readinessProbe"
```

## Resource Cleanup

```bash
# Delete entire deployment
kubectl delete deployment httpd -n <namespace>

# Delete service
kubectl delete svc httpd-service -n <namespace>

# Delete ConfigMap
kubectl delete configmap httpd-config -n <namespace>

# Delete all resources in namespace
kubectl delete all --all -n <namespace>

# Delete namespace
kubectl delete namespace <namespace>
```
