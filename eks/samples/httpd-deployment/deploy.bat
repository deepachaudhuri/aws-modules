@echo off
REM HTTPD Sample Application - Quick Start Script for Windows
REM This script helps you quickly deploy and test the HTTPD application on EKS

setlocal enabledelayedexpansion

echo.
echo ==========================================
echo HTTPD Sample Application - Quick Deploy
echo ==========================================
echo.

REM Check if kubectl is installed
kubectl version --client >nul 2>&1
if errorlevel 1 (
    echo [ERROR] kubectl is not installed. Please install kubectl first.
    echo Visit: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
    pause
    exit /b 1
)

REM Check cluster connection
echo [INFO] Checking EKS cluster connection...
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Cannot connect to EKS cluster. Please configure kubeconfig.
    echo Run: aws eks update-kubeconfig --name lwplabs-cluster --region us-east-1
    pause
    exit /b 1
)
echo [OK] Connected to cluster
echo.

REM Display cluster info
echo [INFO] Cluster Information:
kubectl cluster-info
echo.

REM Create namespace
set /p create_ns="Create a new namespace? (y/n) [y]: "
if "!create_ns!"=="" set create_ns=y

set NAMESPACE=default
if /i "!create_ns!"=="y" (
    set /p NAMESPACE="Enter namespace name [httpd-demo]: "
    if "!NAMESPACE!"=="" set NAMESPACE=httpd-demo
    
    kubectl get namespace !NAMESPACE! >nul 2>&1
    if errorlevel 1 (
        echo [INFO] Creating namespace: !NAMESPACE!
        kubectl create namespace !NAMESPACE!
        echo [OK] Namespace created
    ) else (
        echo [WARNING] Namespace !NAMESPACE! already exists
    )
    echo.
)

REM Deploy application
echo [INFO] Deploying HTTPD application to namespace: !NAMESPACE!
kubectl apply -f deployment.yaml -n !NAMESPACE!

echo [OK] Deployment submitted
echo.

REM Wait for deployment
echo [INFO] Waiting for deployment to be ready (this may take 1-2 minutes)...
timeout /t 5 /nobreak

echo.
echo [INFO] Deployment Status:
kubectl get deployment httpd -n !NAMESPACE!
echo.

REM Show pod status
echo [INFO] Pod Status:
kubectl get pods -n !NAMESPACE! -l app=httpd
echo.

REM Show service
echo [INFO] Service Information:
kubectl get svc httpd-service -n !NAMESPACE!
echo.

REM Quick Access Options
echo [INFO] Quick Access Options:
echo.
echo 1. Port Forward (Local testing):
echo    kubectl port-forward svc/httpd-service 8080:80 -n !NAMESPACE!
echo    Then visit: http://localhost:8080
echo.
echo 2. Convert to LoadBalancer:
echo    kubectl patch svc httpd-service -p "{\"spec\":{\"type\":\"LoadBalancer\"}}" -n !NAMESPACE!
echo    kubectl get svc httpd-service -n !NAMESPACE! -w
echo.
echo 3. Test from within cluster:
echo    kubectl run -it --image=curlimages/curl --restart=Never --rm -- curl http://httpd-service/ -n !NAMESPACE!
echo.

set /p port_forward="Start port forwarding now? (y/n) [n]: "
if /i "!port_forward!"=="y" (
    echo [INFO] Starting port forwarding on port 8080...
    echo Open your browser and visit: http://localhost:8080
    echo Press Ctrl+C to stop port forwarding
    echo.
    kubectl port-forward svc/httpd-service 8080:80 -n !NAMESPACE!
)

echo.
echo ==========================================
echo Setup Complete!
echo ==========================================
echo.
echo To view logs:
echo   kubectl logs -l app=httpd -n !NAMESPACE!
echo.
echo To cleanup:
echo   kubectl delete namespace !NAMESPACE!
echo.
pause
