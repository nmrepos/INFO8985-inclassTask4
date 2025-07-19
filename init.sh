#!/usr/bin/env bash
set -euo pipefail

echo "👉 Deleting any existing kind cluster named sigtest…"
kind delete cluster --name sigtest

echo "👉 Removing any old SigNoz container…"
docker rm -f signoz 2>/dev/null || true

# ─── 1) INSTALL PREREQS ──────────────────────────────────────────────
echo "👉 Installing prerequisites…"
sudo apt-get update
sudo apt-get install -y python3-pip curl

# install kind
echo "👉 Installing kind…"
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/

# install ansible-core (the correct package) and ensure the CLI is on your PATH
echo "👉 Installing ansible-core…"
pip3 install --user ansible-core
pip3 install --user kubernetes
export PATH="$HOME/.local/bin:$PATH"

# install the Kubernetes collection for Ansible
echo "👉 Installing kubernetes.core collection…"
ansible-galaxy collection install kubernetes.core


# ─── 3) START KIND CLUSTER ────────────────────────────────────────────
echo "👉 Creating kind cluster…"
kind create cluster --name sigtest
kubectl cluster-info --context kind-sigtest

# ─── 4) LAUNCH SIGNOZ IN DOCKER ───────────────────────────────────────
echo "👉 Launching SigNoz in Docker (with persistent sqlite dir)…"
mkdir -p ./signoz-data
docker run -d --name signoz \
  -p 3301:3301 -p 3200:3200 \
  -v "$(pwd)/signoz-data":/var/lib/signoz \
  signoz/signoz:latest

# ─── 5) EXPORT DOCKER‑HOST IP ─────────────────────────────────────────
echo "👉 Determining Docker‑bridge IP…"
export DOCKER_HOST_IP=$(ip -4 addr show docker0 \
  | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "   Docker host IP: $DOCKER_HOST_IP"

# ─── 6) DEPLOY THE k8s‑infra CHART ────────────────────────────────────
echo "👉 Deploying k8s-infra chart via Ansible…"
ansible-playbook up.yml \
  -e signoz_backend_url="http://${DOCKER_HOST_IP}:3301"

# wait until all pods are Running
echo "👉 Waiting for SigNoz pods to be Running…"
kubectl get pods -n signoz-system --watch

# ─── 7) DEMO WORKLOAD ────────────────────────────────────────────────
echo "👉 Creating demo workload…"
kubectl create namespace demo
kubectl create deployment nginx-demo \
  --image=nginx \
  --replicas=1 \
  -n demo

# spike it once for metrics
POD=$(kubectl get po -n demo -l app=nginx-demo -o name)
echo "👉 Hitting demo pod once…"
kubectl exec -n demo $POD -- curl -s localhost >/dev/null

# ─── 8) VIEW METRICS IN SIGNOZ ───────────────────────────────────────
echo
echo "🎉 SigNoz is collecting metrics!"
echo "Open in browser: http://localhost:3200"
echo "  • Login: admin@signoz.io / admin"
echo "  • Metrics → Explore → search 'container_cpu_usage_seconds_total'"
echo "  • Filter by namespace=demo, pod=<your-pod-name>"

