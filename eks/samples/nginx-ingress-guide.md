# Nginx Ingress with ALB - Multiple Services Setup

This guide shows how to set up Nginx Ingress Controller with AWS Application Load Balancer (ALB) to manage traffic to multiple microservices in your EKS cluster.

## Table of Contents

- [What is Nginx Ingress?](#what-is-nginx-ingress)
- [Benefits of Nginx Ingress](#benefits-of-nginx-ingress)
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Step 1: Install Nginx Ingress Controller](#step-1-install-nginx-ingress-controller)
- [Step 2: Install AWS Load Balancer Controller](#step-2-install-aws-load-balancer-controller)
- [Step 3: Deploy Multiple Services](#step-3-deploy-multiple-services)
- [Step 4: Create Ingress Rules](#step-4-create-ingress-rules)
- [Step 5: Configure ALB](#step-5-configure-alb)
- [Accessing Your Services](#accessing-your-services)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## What is Nginx Ingress?

**Nginx Ingress Controller** is a Kubernetes Ingress implementation that uses Nginx as a reverse proxy and load balancer. It manages external HTTP/HTTPS access to services running on Kubernetes.

An **Ingress** is a Kubernetes resource that manages external access to services in a cluster, typically HTTP/HTTPS traffic.

### Without Ingress:
```
Internet → LoadBalancer Service 1
         → LoadBalancer Service 2
         → LoadBalancer Service 3
         (Multiple external IPs/costs)
```

### With Ingress:
```
Internet → ALB → Nginx Ingress Controller → Service 1
                                         → Service 2
                                         → Service 3
                                         (Single external IP)
```

---

## Benefits of Nginx Ingress

### 1. **Cost Efficiency**
- ✅ Use a single ALB instead of multiple LoadBalancer services
- ✅ Reduces AWS costs significantly for multiple services
- ✅ Better resource utilization

### 2. **Advanced Routing**
- ✅ Path-based routing: `/login` → Login Service, `/product` → Product Service
- ✅ Host-based routing: `login.example.com` → Login Service
- ✅ Request transformation and manipulation

### 3. **SSL/TLS Termination**
- ✅ Manage HTTPS certificates at the Ingress level
- ✅ Automatic certificate renewal
- ✅ Single point for security configuration

### 4. **Traffic Control**
- ✅ Rate limiting and throttling
- ✅ Canary deployments
- ✅ Circuit breakers and retry logic

### 5. **Unified Management**
- ✅ Centralized configuration for all services
- ✅ Easy to add/remove services
- ✅ Consistent policies across services

### 6. **Production-Ready Features**
- ✅ Load balancing algorithms (round-robin, least connections, etc.)
- ✅ Health checks and monitoring
- ✅ WebSocket support
- ✅ Gzip compression

### 7. **Easy Integration with AWS ALB**
- ✅ Automatic ALB provisioning
- ✅ AWS WAF integration
- ✅ CloudWatch monitoring

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
                  ┌────────────────────────┐
                  │  AWS Application Load  │
                  │      Balancer (ALB)    │
                  └────────────────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
         /login route    /product route   /api route
                │              │              │
                ▼              ▼              ▼
          ┌──────────────────────────────────────┐
          │  Nginx Ingress Controller (Pod)      │
          │  - Reverse Proxy                     │
          │  - Load Balancer                     │
          │  - SSL/TLS Termination               │
          └──────────────────────────────────────┘
                │              │              │
        ┌───────┘              │              └────────┐
        ▼                      ▼                       ▼
    ┌─────────┐         ┌──────────────┐      ┌──────────────┐
    │ Login   │         │ Product      │      │ API          │
    │ Service │         │ Service      │      │ Service      │
    │ (Port   │         │ (Port 3000)  │      │ (Port 8080)  │
    │ 5000)   │         │              │      │              │
    └─────────┘         └──────────────┘      └──────────────┘
        │                      │                      │
        ▼                      ▼                      ▼
    Login App             Product App            API App
```

---

## Prerequisites

Before proceeding, ensure you have:

1. ✅ EKS cluster running (lwplabs-cluster)
2. ✅ kubectl configured and working
3. ✅ Helm package manager installed
4. ✅ AWS credentials configured

### Install Helm (if not already installed)

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

**Verify Helm:**
```bash
helm version
```

---

## Step 1: Install Nginx Ingress Controller

### 1.1 Add Nginx Helm Repository

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

### 1.2 Create Namespace

```bash
kubectl create namespace ingress-nginx
```

### 1.3 Install Nginx Ingress Controller

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-type"="nlb"
```

### 1.4 Verify Installation

```bash
# Check if Nginx pods are running
kubectl get pods -n ingress-nginx

# Get the external IP (this creates a Classic Load Balancer)
kubectl get svc -n ingress-nginx
```

You should see output like:
```
NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP
nginx-ingress-controller   LoadBalancer   172.20.x.x       a1234567890abcdef-1234567890.us-east-1.elb.amazonaws.com
```

---

## Step 2: Install AWS Load Balancer Controller (Optional - for better ALB integration)

If you want to use AWS ALB annotations for more control:

```bash
# Add AWS EKS Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=lwplabs-cluster \
  --set serviceAccount.create=true
```

---

## Step 3: Deploy Multiple Services

Create a directory for the services:

```bash
mkdir -p multi-services
cd multi-services
```

### 3.1 Login Service

Create `login-service.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: services
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: login-config
  namespace: services
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Login Service</title>
      <style>
        body { font-family: Arial; margin: 40px; background-color: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 8px; max-width: 500px; margin: 0 auto; }
        h1 { color: #e74c3c; border-bottom: 3px solid #e74c3c; }
        .info { background: #fff3cd; padding: 15px; border-left: 4px solid #e74c3c; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🔐 Login Service</h1>
        <div class="info">
          <p><strong>Service Name:</strong> Login Service</p>
          <p><strong>Port:</strong> 5000</p>
          <p><strong>Route:</strong> /login</p>
          <p><strong>Pod:</strong> POD_NAME</p>
        </div>
        <p>This is the login microservice for user authentication.</p>
      </div>
    </body>
    </html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: login-app
  namespace: services
  labels:
    app: login
spec:
  replicas: 2
  selector:
    matchLabels:
      app: login
  template:
    metadata:
      labels:
        app: login
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        ports:
        - containerPort: 80
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: html-config
          mountPath: /usr/local/apache2/htdocs/
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                sed "s|POD_NAME|${POD_NAME}|g" /usr/local/apache2/htdocs/index.html > /tmp/index.html
                mv /tmp/index.html /usr/local/apache2/htdocs/index.html
      volumes:
      - name: html-config
        configMap:
          name: login-config
---
apiVersion: v1
kind: Service
metadata:
  name: login-service
  namespace: services
  labels:
    app: login
spec:
  type: ClusterIP
  selector:
    app: login
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    name: http
```

### 3.2 Product Service

Create `product-service.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: product-config
  namespace: services
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>Product Service</title>
      <style>
        body { font-family: Arial; margin: 40px; background-color: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 8px; max-width: 500px; margin: 0 auto; }
        h1 { color: #27ae60; border-bottom: 3px solid #27ae60; }
        .info { background: #d4edda; padding: 15px; border-left: 4px solid #27ae60; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>📦 Product Service</h1>
        <div class="info">
          <p><strong>Service Name:</strong> Product Service</p>
          <p><strong>Port:</strong> 3000</p>
          <p><strong>Route:</strong> /product</p>
          <p><strong>Pod:</strong> POD_NAME</p>
        </div>
        <p>This is the product microservice for product management.</p>
      </div>
    </body>
    </html>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-app
  namespace: services
  labels:
    app: product
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product
  template:
    metadata:
      labels:
        app: product
    spec:
      containers:
      - name: httpd
        image: httpd:2.4-alpine
        ports:
        - containerPort: 80
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: html-config
          mountPath: /usr/local/apache2/htdocs/
        lifecycle:
          postStart:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                sed "s|POD_NAME|${POD_NAME}|g" /usr/local/apache2/htdocs/index.html > /tmp/index.html
                mv /tmp/index.html /usr/local/apache2/htdocs/index.html
      volumes:
      - name: html-config
        configMap:
          name: product-config
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: services
  labels:
    app: product
spec:
  type: ClusterIP
  selector:
    app: product
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
    name: http
```

### 3.3 Deploy Services

```bash
kubectl apply -f login-service.yaml
kubectl apply -f product-service.yaml

# Verify services are running
kubectl get pods -n services
kubectl get svc -n services
```

---

## Step 4: Create Ingress Rules

Create `ingress-rules.yaml`:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-service-ingress
  namespace: services
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
spec:
  rules:
  # Login service routing
  - http:
      paths:
      - path: /login
        pathType: Prefix
        backend:
          service:
            name: login-service
            port:
              number: 80
  
  # Product service routing
  - http:
      paths:
      - path: /product
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 80
  
  # Default backend
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: login-service
            port:
              number: 80
```

Deploy the Ingress:

```bash
kubectl apply -f ingress-rules.yaml

# Verify Ingress is created
kubectl get ingress -n services
kubectl describe ingress multi-service-ingress -n services
```

---

## Step 5: Configure ALB

### Option 1: Using Nginx Ingress (Already Done Above)

Your Nginx Ingress Controller is already exposing through a Network Load Balancer.

### Option 2: Using AWS Load Balancer Controller with ALB Annotations

If you installed the AWS Load Balancer Controller, you can create an ALB Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-service-alb
  namespace: services
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/group.name: multi-service-group
    alb.ingress.kubernetes.io/group.order: '1'
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /login
        pathType: Prefix
        backend:
          service:
            name: login-service
            port:
              number: 80
      - path: /product
        pathType: Prefix
        backend:
          service:
            name: product-service
            port:
              number: 80
```

---

## Accessing Your Services

### Get the External URL

```bash
# Get Nginx Ingress external IP/DNS
kubectl get svc -n ingress-nginx

# Example output:
# nginx-ingress-controller   LoadBalancer   172.20.x.x   a1234567890abcdef.elb.us-east-1.amazonaws.com
```

### Access Services

Using the external DNS name from above (e.g., `a1234567890abcdef.elb.us-east-1.amazonaws.com`):

```bash
# Access Login Service
curl http://a1234567890abcdef.elb.us-east-1.amazonaws.com/login

# Access Product Service
curl http://a1234567890abcdef.elb.us-east-1.amazonaws.com/product

# Access via browser
# http://a1234567890abcdef.elb.us-east-1.amazonaws.com/login
# http://a1234567890abcdef.elb.us-east-1.amazonaws.com/product
```

### Port Forward (for local testing)

```bash
# Port forward Nginx Ingress
kubectl port-forward -n ingress-nginx svc/nginx-ingress-controller 8080:80

# Then access
curl http://localhost:8080/login
curl http://localhost:8080/product

# Or in browser
# http://localhost:8080/login
# http://localhost:8080/product
```

---

## Troubleshooting

### Check Ingress Status

```bash
kubectl get ingress -n services
kubectl describe ingress multi-service-ingress -n services
kubectl get events -n services
```

### Check Nginx Ingress Logs

```bash
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx -f
```

### Verify Service Connectivity

```bash
# Test from Nginx pod
kubectl exec -it -n ingress-nginx deployment/nginx-ingress-controller -- curl http://login-service.services:80

# Test from debug pod
kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://login-service.services:80
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Ingress shows no IP | Wait 1-2 minutes for ALB to provision |
| 502 Bad Gateway | Check if services are running: `kubectl get pods -n services` |
| Services not responding | Verify Ingress rules: `kubectl describe ingress -n services` |
| ALB not created | Check AWS Load Balancer Controller logs |

---

## Cleanup

```bash
# Delete Ingress
kubectl delete ingress -n services --all

# Delete services
kubectl delete -f login-service.yaml
kubectl delete -f product-service.yaml

# Delete namespace
kubectl delete namespace services

# Delete Nginx Ingress
helm uninstall nginx-ingress -n ingress-nginx
kubectl delete namespace ingress-nginx
```

---

## Summary

| Component | Purpose | Cost Impact |
|-----------|---------|------------|
| **Nginx Ingress Controller** | Routes traffic to services | 1 pod (minimal) |
| **AWS ALB/NLB** | Entry point for external traffic | ~$16/month |
| **Multiple Services** | Individual microservices | Depends on replicas |
| **Total Cost Savings** | vs multiple LoadBalancer services | ~70% less |

You now have a production-ready setup with:
- ✅ Single entry point (ALB/NLB)
- ✅ Path-based routing to multiple services
- ✅ Easy service management
- ✅ Cost-effective architecture
- ✅ Production-grade load balancing
