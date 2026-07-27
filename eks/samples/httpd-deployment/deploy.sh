#!/bin/bash

# HTTPD Sample Application - Quick Start Script
# This script helps you quickly deploy and test the HTTPD application on EKS

set -e

echo "=========================================="
echo "HTTPD Sample Application - Quick Deploy"
echo "=========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}❌ kubectl is not installed. Please install kubectl first.${NC}"
    echo "Visit: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
    exit 1
fi

# Check cluster connection
echo -e "${BLUE}Checking EKS cluster connection...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${YELLOW}❌ Cannot connect to EKS cluster. Please configure kubeconfig.${NC}"
    echo "Run: aws eks update-kubeconfig --name lwplabs-cluster --region us-east-1"
    exit 1
fi
echo -e "${GREEN}✓ Connected to cluster${NC}"
echo ""

# Display cluster info
echo -e "${BLUE}Cluster Information:${NC}"
kubectl cluster-info
echo ""

# Create namespace
read -p "Create a new namespace? (y/n) [y]: " create_ns
create_ns=${create_ns:-y}

NAMESPACE="default"
if [ "$create_ns" = "y" ] || [ "$create_ns" = "Y" ]; then
    read -p "Enter namespace name [httpd-demo]: " namespace_input
    NAMESPACE=${namespace_input:-httpd-demo}
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${BLUE}Creating namespace: $NAMESPACE${NC}"
        kubectl create namespace $NAMESPACE
        echo -e "${GREEN}✓ Namespace created${NC}"
    else
        echo -e "${YELLOW}Namespace $NAMESPACE already exists${NC}"
    fi
    echo ""
fi

# Deploy application
echo -e "${BLUE}Deploying HTTPD application to namespace: $NAMESPACE${NC}"
kubectl apply -f deployment.yaml -n $NAMESPACE

echo -e "${GREEN}✓ Deployment submitted${NC}"
echo ""

# Wait for deployment
echo -e "${BLUE}Waiting for deployment to be ready (this may take 1-2 minutes)...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/httpd -n $NAMESPACE 2>/dev/null || true

echo ""
echo -e "${BLUE}Deployment Status:${NC}"
kubectl get deployment httpd -n $NAMESPACE
echo ""

# Show pod status
echo -e "${BLUE}Pod Status:${NC}"
kubectl get pods -n $NAMESPACE -l app=httpd
echo ""

# Show service
echo -e "${BLUE}Service Information:${NC}"
kubectl get svc httpd-service -n $NAMESPACE
echo ""

# Port forward setup
echo -e "${YELLOW}Quick Access Options:${NC}"
echo ""
echo "1. Port Forward (Local testing):"
echo "   kubectl port-forward svc/httpd-service 8080:80 -n $NAMESPACE"
echo "   Then visit: http://localhost:8080"
echo ""

echo "2. Convert to LoadBalancer:"
echo "   kubectl patch svc httpd-service -p '{\"spec\":{\"type\":\"LoadBalancer\"}}' -n $NAMESPACE"
echo "   kubectl get svc httpd-service -n $NAMESPACE -w"
echo ""

echo "3. Test from within cluster:"
echo "   kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://httpd-service/  -n $NAMESPACE"
echo ""

# Auto port-forward option
read -p "Start port forwarding now? (y/n) [n]: " port_forward
if [ "$port_forward" = "y" ] || [ "$port_forward" = "Y" ]; then
    echo -e "${BLUE}Starting port forwarding on port 8080...${NC}"
    echo "Open your browser and visit: http://localhost:8080"
    echo "Press Ctrl+C to stop port forwarding"
    echo ""
    kubectl port-forward svc/httpd-service 8080:80 -n $NAMESPACE
fi

echo ""
echo -e "${GREEN}=========================================="
echo "Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "To view logs:"
echo "  kubectl logs -l app=httpd -n $NAMESPACE"
echo ""
echo "To cleanup:"
echo "  kubectl delete namespace $NAMESPACE"
echo ""
