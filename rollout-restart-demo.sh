#!/bin/bash

# Script to rollout restart all OpenTelemetry Demo components
# Usage: ./rollout-restart-demo.sh [namespace]

NAMESPACE=${1:-otel-demo}

echo "🔄 Rolling out restart for OpenTelemetry Demo components in namespace: $NAMESPACE"
echo "=================================================="

# Array of all components from values.yaml
COMPONENTS=(
    "accounting"
    "ad"
    "cart"
    "checkout"
    "currency"
    "email"
    "fraud-detection"
    "frontend"
    "frontend-proxy"
    "image-provider"
    "load-generator"
    "payment"
    "product-catalog"
    "quote"
    "recommendation"
    "shipping"
    "flagd"
    "kafka"
    "valkey-cart"
)

# Infrastructure components (from dependencies)
INFRA_COMPONENTS=(
    "jaeger"
    "prometheus"
    "grafana"
    "opensearch"
    "otel-demo-daemon-collector"
)

# Function to rollout restart a deployment
rollout_restart() {
    local component=$1
    local deployment_name=$2

    echo "🔄 Restarting $component..."

    if kubectl get deployment "$deployment_name" -n "$NAMESPACE" &> /dev/null; then
        kubectl rollout restart deployment/"$deployment_name" -n "$NAMESPACE"
        if [ $? -eq 0 ]; then
            echo "✅ Successfully restarted $component ($deployment_name)"
        else
            echo "❌ Failed to restart $component ($deployment_name)"
        fi
    else
        echo "⚠️  Deployment $deployment_name not found (component may be disabled)"
    fi
    echo ""
}

# Function to wait for rollout to complete
wait_for_rollout() {
    local deployment_name=$1
    echo "⏳ Waiting for $deployment_name rollout to complete..."
    kubectl rollout status deployment/"$deployment_name" -n "$NAMESPACE" --timeout=300s
    echo ""
}

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "❌ Namespace '$NAMESPACE' does not exist!"
    echo "Available namespaces:"
    kubectl get namespaces
    exit 1
fi

echo "📋 Found namespace: $NAMESPACE"
echo ""

# Restart demo components
echo "🚀 Restarting Demo Components..."
echo "================================"

for component in "${COMPONENTS[@]}"; do
    rollout_restart "$component" "$component"
done

# Restart infrastructure components
echo "🏗️  Restarting Infrastructure Components..."
echo "=========================================="

for component in "${INFRA_COMPONENTS[@]}"; do
    rollout_restart "$component" "$component"
done

# Optional: Wait for all rollouts to complete
read -p "🤔 Do you want to wait for all rollouts to complete? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⏳ Waiting for all rollouts to complete..."
    echo "========================================"

    # Get all deployments in the namespace
    DEPLOYMENTS=$(kubectl get deployments -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')

    for deployment in $DEPLOYMENTS; do
        wait_for_rollout "$deployment"
    done

    echo "🎉 All rollouts completed!"
else
    echo "ℹ️  You can check rollout status manually with:"
    echo "   kubectl rollout status deployment/<deployment-name> -n $NAMESPACE"
fi

echo ""
echo "📊 Current deployment status:"
echo "============================"
kubectl get deployments -n "$NAMESPACE"

echo ""
echo "📈 Pod status:"
echo "============="
kubectl get pods -n "$NAMESPACE"

echo ""
echo "✅ Rollout restart script completed!"
