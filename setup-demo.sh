#!/bin/bash

# Setup script for GitHub Codespace demonstration
# This script prepares the environment for running the Ansible playbooks

set -e

echo "🚀 Setting up Kubernetes Infrastructure Monitoring Demo"
echo "=================================================="

# Check if we're in a codespace
if [ "$CODESPACES" = "true" ]; then
    echo "✅ Running in GitHub Codespace"
else
    echo "⚠️  Not in GitHub Codespace, but continuing..."
fi

echo ""
echo "📦 Installing dependencies..."

# Install kubectl if not present
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "✅ kubectl already installed"
fi

# Install helm if not present
if ! command -v helm &> /dev/null; then
    echo "Installing helm..."
    curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
    sudo mv linux-amd64/helm /usr/local/bin/
    rm -rf linux-amd64
else
    echo "✅ helm already installed"
fi

# Install kind if not present (for local k8s cluster)
if ! command -v kind &> /dev/null; then
    echo "Installing kind..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/
else
    echo "✅ kind already installed"
fi

# Install Ansible collections
echo ""
echo "📚 Installing Ansible collections..."
cd ansible
ansible-galaxy collection install -r requirements.yaml --force

echo ""
echo "🔧 Setting up local Kubernetes cluster with kind..."

# Create kind cluster if it doesn't exist
if ! kind get clusters | grep -q "demo-cluster"; then
    cat > kind-config.yaml << EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: demo-cluster
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
- role: worker
- role: worker
EOF

    kind create cluster --config kind-config.yaml
    echo "✅ Kind cluster created"
else
    echo "✅ Kind cluster already exists"
fi

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

echo ""
echo "🎯 Demo Setup Complete!"
echo "========================"
echo ""
echo "Next steps:"
echo "1. Update ansible/group_vars/all.yaml with your SigNoz endpoint"
echo "2. Run: cd ansible && ansible-playbook up.yaml"
echo "3. Test: kubectl get pods -n monitoring"
echo ""
echo "For SigNoz in Codespace demo, you can use:"
echo "  signoz_otel_endpoint: 'localhost:4317'"
echo "  (if running SigNoz locally in the codespace)"
echo ""
