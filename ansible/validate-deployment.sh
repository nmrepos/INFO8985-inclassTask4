#!/bin/bash

# Validation script for K8s Infrastructure Monitoring deployment
# This script checks if all components are properly deployed and functioning

NAMESPACE="monitoring"
TIMEOUT=300

echo "🔍 Validating Kubernetes Infrastructure Monitoring Deployment"
echo "============================================================="

# Function to check if pods are ready
check_pods_ready() {
    local label_selector=$1
    local component_name=$2
    
    echo "📋 Checking $component_name pods..."
    kubectl wait --for=condition=ready pod -l "$label_selector" -n "$NAMESPACE" --timeout="${TIMEOUT}s"
    
    if [ $? -eq 0 ]; then
        echo "✅ $component_name pods are ready"
        return 0
    else
        echo "❌ $component_name pods are not ready"
        return 1
    fi
}

# Function to check if service is available
check_service() {
    local service_name=$1
    
    echo "🔍 Checking service: $service_name"
    kubectl get service "$service_name" -n "$NAMESPACE" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ Service $service_name exists"
        return 0
    else
        echo "❌ Service $service_name not found"
        return 1
    fi
}

# Function to test connectivity
test_connectivity() {
    echo "🌐 Testing application connectivity..."
    
    # Port forward rolldice service
    kubectl port-forward -n "$NAMESPACE" service/rolldice-service 8080:80 &
    local port_forward_pid=$!
    
    # Wait a moment for port forward to establish
    sleep 5
    
    # Test connection
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/rolldice 2>/dev/null)
    
    # Kill port forward
    kill $port_forward_pid 2>/dev/null
    
    if [ "$response" = "200" ]; then
        echo "✅ Rolldice application is responding"
        return 0
    else
        echo "❌ Rolldice application is not responding (HTTP: $response)"
        return 1
    fi
}

# Main validation
echo "🚀 Starting validation process..."
echo

# Check if namespace exists
echo "📁 Checking namespace: $NAMESPACE"
kubectl get namespace "$NAMESPACE" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Namespace $NAMESPACE exists"
else
    echo "❌ Namespace $NAMESPACE not found"
    exit 1
fi

echo

# Check k8s-infra components
check_pods_ready "app.kubernetes.io/name=k8s-infra" "K8s-Infra OTEL Collectors"
k8sinfra_status=$?

echo

# Check rolldice application
check_pods_ready "app=rolldice" "Rolldice Application"
rolldice_status=$?

echo

# Check services
check_service "rolldice-service"
service_status=$?

echo

# Test connectivity
test_connectivity
connectivity_status=$?

echo
echo "📊 Validation Summary"
echo "===================="

# Summary
total_checks=4
passed_checks=0

if [ $k8sinfra_status -eq 0 ]; then ((passed_checks++)); fi
if [ $rolldice_status -eq 0 ]; then ((passed_checks++)); fi
if [ $service_status -eq 0 ]; then ((passed_checks++)); fi
if [ $connectivity_status -eq 0 ]; then ((passed_checks++)); fi

echo "Passed: $passed_checks/$total_checks checks"

if [ $passed_checks -eq $total_checks ]; then
    echo "🎉 All validations passed! Your deployment is working correctly."
    echo
    echo "📍 Next Steps:"
    echo "  1. Access your SigNoz dashboard to view metrics and traces"
    echo "  2. Generate more test traffic: kubectl port-forward -n $NAMESPACE service/rolldice-service 8080:80"
    echo "  3. Then run: curl http://localhost:8080/rolldice"
    echo "  4. Check SigNoz for the telemetry data"
    exit 0
else
    echo "⚠️  Some validations failed. Please check the deployment."
    echo
    echo "🔧 Troubleshooting commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=k8s-infra"
    echo "  kubectl logs -n $NAMESPACE -l app=rolldice"
    exit 1
fi
