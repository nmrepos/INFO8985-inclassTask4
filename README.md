# INFO8985-inclassTask4 - Kubernetes Infrastructure Monitoring with SigNoz

This repository contains Ansible playbooks and roles for deploying Kubernetes infrastructure monitoring using SigNoz's k8s-infra helm chart, along with a sample rolldice application for testing telemetry collection.

## Features

- **Automated K8s-Infra Deployment**: Installs and configures SigNoz k8s-infra helm chart for comprehensive Kubernetes monitoring
- **Configurable OTEL Collector**: Override values to specify upstream OpenTelemetry collector endpoint (e.g., SigNoz running in TrueNAS)
- **Sample Application**: Deploys rolldice app with OpenTelemetry instrumentation to test telemetry flow
- **Environment Management**: Easy deployment and removal with `up.yaml` and `down.yaml` playbooks

## Prerequisites

1. **Kubernetes Cluster**: Running Kubernetes cluster with kubectl configured
2. **Ansible**: Ansible 2.10+ with kubernetes.core collection
3. **Helm**: Helm 3.x installed and configured
4. **SigNoz Instance**: SigNoz running (e.g., in TrueNAS via Docker)

## Quick Start

### 1. Install Dependencies

```bash
# Install required Ansible collections
ansible-galaxy collection install -r ansible/requirements.yaml

# Or install individually
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.general
```

### 2. Configure Variables

Edit `ansible/group_vars/all.yaml` to match your environment:

```yaml
# Update this to point to your SigNoz instance
signoz_otel_endpoint: "192.168.1.100:4317"  # Your TrueNAS SigNoz IP:port
cluster_name: "my-k8s-cluster"
deployment_environment: "development"
```

### 3. Deploy Infrastructure Monitoring

```bash
cd ansible
ansible-playbook up.yaml
```

### 4. Remove Everything

```bash
cd ansible
ansible-playbook down.yaml
```

## Configuration

### Key Configuration Options

The main configuration is in `ansible/group_vars/all.yaml`:

- **signoz_otel_endpoint**: Your SigNoz OTEL collector endpoint
- **signoz_otel_insecure**: Set to `true` for self-hosted SigNoz without TLS
- **cluster_name**: Unique identifier for your K8s cluster
- **k8sinfra_values**: Helm chart values override

### OTEL Collector Override

The key feature is the ability to override the OTEL collector endpoint:

```yaml
k8sinfra_values:
  # This sends data to your custom SigNoz instance
  otelCollectorEndpoint: "{{ signoz_otel_endpoint }}"
  otelInsecure: "{{ signoz_otel_insecure }}"
  
  presets:
    otlpExporter:
      enabled: true
    logsCollection:
      enabled: true
    hostMetrics:
      enabled: true
    kubeletMetrics:
      enabled: true
    clusterMetrics:
      enabled: true
```

## What Gets Deployed

### K8s-Infra Components
- **OTEL Collector DaemonSet**: Collects metrics and logs from each node
- **OTEL Collector Deployment**: Acts as gateway for application telemetry
- **Kubernetes Receivers**: Monitors kubelet, cluster metrics, and host metrics
- **Log Collection**: Tails container logs and forwards to SigNoz

### Rolldice Application
- **Deployment**: 2 replicas of instrumented sample application
- **Service**: ClusterIP service for internal access
- **Test Traffic Generator**: Job that creates sample requests for testing

## Monitoring Components

The setup monitors:

### Infrastructure Metrics
- Node CPU, memory, disk, network utilization
- Pod resource usage and status
- Kubernetes cluster metrics
- Container filesystem metrics

### Application Metrics
- Custom application metrics from rolldice app
- HTTP request traces and metrics
- Service performance data

### Logs
- Container logs from all pods
- Kubernetes events
- Application logs with structured data

## Verification

### Check Deployment Status

```bash
# Verify k8s-infra pods
kubectl get pods -n monitoring

# Check services
kubectl get services -n monitoring

# View logs
kubectl logs -n monitoring -l app.kubernetes.io/name=k8s-infra
```

### Test Rolldice Application

```bash
# Port forward to access locally
kubectl port-forward -n monitoring service/rolldice-service 8080:80

# Generate test requests
curl http://localhost:8080/rolldice
```

### Verify Data in SigNoz

1. Open your SigNoz dashboard (e.g., http://192.168.1.100:3301)
2. Check for:
   - Kubernetes infrastructure metrics in Metrics section
   - Rolldice application traces in Traces section
   - Container logs in Logs section

## Customization


### Different Environments & Codespaces Demo

You can use different variable files for different environments. For GitHub Codespaces or demo environments, use the provided `codespace.yaml`:

```bash
# To use the Codespace demo config:
cd ansible
ansible-playbook up.yaml -e @group_vars/codespace.yaml
```

Or for your own environment, copy and modify:

```bash
cp ansible/group_vars/all.yaml ansible/group_vars/production.yaml
# Then edit production.yaml as needed
```

> **Tip:** The playbooks default to `all.yaml` unless you specify another file with `-e @group_vars/yourenv.yaml`.

### Custom Applications

Follow the rolldice role pattern to deploy your own instrumented applications:

1. Copy `ansible/roles/rolldice` to `ansible/roles/your-app`
2. Modify the deployment manifest with your application image
3. Ensure OTEL environment variables are configured
4. Add the role to your playbooks

### Advanced Configuration

Modify `k8sinfra_values` in group_vars to:
- Disable specific metric collection
- Configure resource limits
- Add custom OTEL processor configurations
- Setup different sampling rates

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource constraints and node capacity
2. **No data in SigNoz**: Verify OTEL endpoint and network connectivity
3. **Permission errors**: Ensure kubectl has proper cluster access

### Debug Commands

```bash
# Check k8s-infra collector logs
kubectl logs -n monitoring -l app.kubernetes.io/name=k8s-infra -f

# Check rolldice application logs
kubectl logs -n monitoring -l app=rolldice -f

# Verify OTEL configuration
kubectl get configmap -n monitoring
```

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Kubernetes    │    │   K8s-Infra      │    │     SigNoz      │
│   Cluster       │───▶│   OTEL           │───▶│   (TrueNAS)     │
│                 │    │   Collectors     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Rolldice      │    │   Metrics        │    │   Dashboards    │
│   Application   │───▶│   Traces         │───▶│   Alerts        │
│   (Sample)      │    │   Logs           │    │   Analytics     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Files Structure

```
ansible/
├── up.yaml                 # Main deployment playbook
├── down.yaml               # Removal playbook
├── ansible.cfg             # Ansible configuration
├── inventory               # Inventory file
├── requirements.yaml       # Ansible collection requirements
├── group_vars/
│   ├── all.yaml           # Main configuration variables
│   └── environments.yaml   # Environment-specific examples
└── roles/
    ├── k8sinfra/          # K8s infrastructure monitoring role
    │   ├── tasks/main.yaml
    │   ├── defaults/main.yaml
    │   └── meta/main.yaml
    └── rolldice/           # Sample application role
        ├── tasks/main.yaml
        ├── defaults/main.yaml
        └── meta/main.yaml
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with your Kubernetes cluster
5. Submit a pull request

## License

This project is for educational purposes as part of INFO8985 coursework.