# K8s Infra Helm Setup with Signoz

This repository contains Ansible playbooks to deploy the [k8s-infra](https://github.com/SigNoz/k8s-infra) Helm chart and a sample `rolldice` application. The chart forwards Kubernetes logs to an upstream OpenTelemetry collector (e.g. SigNoz running on TrueNAS).

## Prerequisites

- Kubernetes cluster reachable from the host running Ansible
- Helm and kubectl configured for the cluster
- Ansible installed
- Access to a SigNoz OpenTelemetry collector endpoint

Install required Ansible collections:

```bash
ansible-galaxy collection install -r ansible/requirements.yml
```

## Usage

1. Set the collector endpoint by editing `ansible/up.yaml` or passing it on the command line:

```bash
ansible-playbook ansible/up.yaml -e otel_collector_endpoint=http://collector:4317
```

2. To remove all deployed resources:

```bash
ansible-playbook ansible/down.yaml
```

3. After deployment, generate some telemetry with the helper script:

```bash
./test.sh
```

Then open the SigNoz UI to confirm traces and logs from `rolldice` are visible.
