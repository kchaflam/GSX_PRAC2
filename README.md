# GSX_PRAC2 - Organizational IT Infrastructure

## Overview

This repository contains the infrastructure definition and operational documentation for a two-service application:

- an Nginx frontend serving static content
- a Python HTTP backend exposing a simple service and persistent runtime logs

The stack can run locally with Docker Compose or on a local Kubernetes cluster with Terraform. The Kubernetes deployment includes health probes, resource limits, namespaces for multiple environments, NetworkPolicies for traffic segmentation, and a CI pipeline that builds container images and validates Terraform.

---

## Repository Structure

```text
.
|-- Containers/              # Dockerfiles and application source code
|-- docker-compose/          # Local Compose stack and environment configuration
|-- Kubernetes/              # Raw Kubernetes manifests for a simple deployment
|-- KubernetesPolicies/      # Namespaces and NetworkPolicy manifests
|-- Terraform/               # Kubernetes infrastructure managed as code
|-- Documentation/           # Operational manuals, diagrams, and design notes
`-- .github/workflows/       # CI pipeline
```

---

## Quick Start

### Docker Compose

Use this path for local development and quick functional checks.

```bash
cd docker-compose
docker-compose up --build
```

Nginx is available at `http://localhost:80` and the backend at `http://localhost:8080`.

Stop the stack:

```bash
docker-compose down
```

### Kubernetes with Terraform

Use this path for the full local infrastructure deployment.

```bash
minikube start
cd Terraform
terraform init
terraform apply
```

Terraform deploys the stack into `development`, `staging`, and `production`, then prints the NodePort assigned to Nginx in each environment.

Check the outputs:

```bash
terraform output nginx_node_ports
```

Destroy the Terraform-managed resources:

```bash
terraform destroy
```

### Raw Kubernetes Manifests

Use this path for a basic Kubernetes deployment without Terraform.

```bash
minikube start
kubectl apply -f Kubernetes/
kubectl get pods
```

The raw manifests deploy into the default namespace and expose Nginx on NodePort `30080`.

---

## Documentation

### Containers

- [Nginx Container](Documentation/Containers/NginxContainer.md)
- [Python Container](Documentation/Containers/PythonContainer.md)
- [Docker Troubleshooting](Documentation/Containers/DockerTroubleshooting.md)

### Docker Compose

- [Compose Structure](Documentation/DockerCompose/ComposeStructure.md)
- [Compose Run Guide](Documentation/DockerCompose/ComposeRunGuide.md)
- [Compose Troubleshooting](Documentation/DockerCompose/ComposeTroubleshooting.md)

### Kubernetes

- [Kubernetes Structure](Documentation/Kubernetes/KubernetesStructure.md)
- [Kubernetes Run Guide](Documentation/Kubernetes/KubernetesRunGuide.md)
- [Scaling & Resilience](Documentation/Kubernetes/KubernetesScaling.md)
- [Kubernetes Troubleshooting](Documentation/Kubernetes/KubernetesTroubleshooting.md)

### Terraform & CI/CD

- [Terraform Structure](Documentation/Terraform/TerraformStructure.md)
- [Terraform Run Guide](Documentation/Terraform/TerraformRunGuide.md)
- [CI/CD Pipeline](Documentation/Terraform/TerraformCICD.md)
- [Terraform Troubleshooting](Documentation/Terraform/TerraformTroubleshooting.md)

### Integration & Operations

- [System Validation & Operational Runbook](Documentation/Integration/FullIntegrationTest.md)

### Network & Identity

- [Network Design](Documentation/Network/NetworkDesign.md)
- [Network Policies](Documentation/Network/NetworkPolicies.md)
- [Core Services - DNS, DHCP, NTP](Documentation/Network/CoreServices.md)
- [Identity Management](Documentation/Network/IdentityManagement.md)
