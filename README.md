# Signoz K8S‑Infra Demo with Ansible

This repo shows how to:

1. **Run Signoz** in Docker (backend + UI).
2. **Install** the Signoz `k8s‑infra-metrics` Helm chart into your Kubernetes cluster using Ansible (`up.yaml`).
3. **Uninstall** it again with Ansible (`down.yaml`).

---

### 1. Prerequisites

- A Kubernetes cluster reachable from your Codespace (e.g. `kind create cluster`, `microk8s start`, or `k3d cluster create`).
- `kubectl` configured to talk to it.
- Docker (to run Signoz locally).
- Ansible 2.10+ with the `community.kubernetes` collection:
  ```bash
  ansible-galaxy collection install community.kubernetes
