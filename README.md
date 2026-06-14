# GSX_PRAC2 — Organizational IT Infrastructure

## Overview

This project covers the containerization, orchestration, and deployment of a two-service application: an Nginx web server serving static content and a Python HTTP backend that handles requests and writes persistent logs. The goal is to build a complete infrastructure stack from scratch, progressively adding layers of tooling and automation.

The stack starts with individual Docker containers, moves to Docker Compose for local multi-container orchestration, then to Kubernetes for production-grade deployment with health checks, resource limits, and automatic recovery. Terraform is used as Infrastructure as Code to define and manage the Kubernetes resources reproducibly, and a GitHub Actions CI/CD pipeline automates image builds and infrastructure validation on every push to main.

The project also covers network architecture design, Kubernetes NetworkPolicies for traffic segmentation, and research into core network services and identity management strategies for a growing organization.

---

## Project Structure

```
.
├── Containers/             # Dockerfiles and application source code
├── Docker-Compose/         # Compose stack definition and environment config
├── Kubernetes/             # Raw Kubernetes manifest files
├── KubernetesPolicies/     # Raw Kubernetes manifest files (separated by dev/prod + network policies)
├── Terraform/              # Infrastructure as Code for Kubernetes resources
└── Documentation/          # All documentation organized by topic
```

---

## Quick Start

### Option 1 — Docker Compose (recommended for local development)

The fastest way to get the full stack running locally. Requires Docker and Docker Compose installed.

```bash
cd Docker-Compose
docker-compose up --build
```

Nginx will be available at `http://localhost:80` and the backend at `http://localhost:8080`. To stop the stack run `docker-compose down`.

### Option 2 — Kubernetes with Terraform (recommended for full deployment)

Deploys the stack to a local Minikube cluster using Terraform. Requires Minikube, kubectl, and Terraform installed.

```bash
minikube start
cd Terraform
terraform init
terraform apply
```

Terraform will deploy the stack into `development`, `staging`, and `production`, then print the NodePort assigned to Nginx in each environment. Use `minikube ip` combined with the port for the environment you want to test. To tear everything down run `terraform destroy`.

### Option 3 — Kubernetes with raw manifests

Deploys the stack directly using the Kubernetes manifest files without Terraform.

```bash
minikube start
kubectl apply -f Kubernetes/
kubectl get pods
```

---

## Documentation

### Containers

Individual container documentation covering Dockerfile design decisions, base image choices, build and run instructions, and security considerations.

- [Nginx Container](Documentation/Containers/NginxContainer.md)
- [Python Container](Documentation/Containers/PythonContainer.md)
- [Docker Troubleshooting](Documentation/Containers/DockerTroubleshooting.md)

### Docker Compose

Documentation for the multi-container stack including service definitions, networking, volumes, health checks, and environment variable configuration.

- [Compose Structure](Documentation/DockerCompose/ComposeStructure.md)
- [Compose Run Guide](Documentation/DockerCompose/ComposeRunGuide.md)
- [Compose Troubleshooting](Documentation/DockerCompose/ComposeTroubleshooting.md)

### Kubernetes

Covers the Kubernetes resources used in the deployment, how to set up and interact with the cluster, scaling and resilience testing, and common issues.

- [Kubernetes Structure](Documentation/Kubernetes/KubernetesStructure.md)
- [Kubernetes Run Guide](Documentation/Kubernetes/KubernetesRunGuide.md)
- [Scaling & Resilience](Documentation/Kubernetes/KubernetesScaling.md)
- [Kubernetes Troubleshooting](Documentation/Kubernetes/KubernetesTroubleshooting.md)

### Terraform & CI/CD

Documents the Terraform configuration for managing Kubernetes resources as code, the deployment workflow, and the GitHub Actions pipeline that builds and validates on every push.

- [Terraform Structure](Documentation/Terraform/TerraformStructure.md)
- [Terraform Run Guide](Documentation/Terraform/TerraformRunGuide.md)
- [CI/CD Pipeline](Documentation/Terraform/TerraformCICD.md)
- [Terraform Troubleshooting](Documentation/Terraform/TerraformTroubleshooting.md)

### Network & Identity

Covers the network architecture design with IP addressing and segmentation, Kubernetes NetworkPolicies for enforcing traffic boundaries, and research into DNS, DHCP, NTP, and identity management for a growing organization.

- [Network Design](Documentation/Network/NetworkDesign.md)
- [Network Policies](Documentation/Network/NetworkPolicies.md)
- [Core Services — DNS, DHCP, NTP](Documentation/Network/CoreServices.md)
- [Identity Management](Documentation/Network/IdentityManagement.md)

### Other

- [Kevin's Essay](Documentation/Reflection/KevinEssay.md)
- [Javier's Essay](Documentation/Reflection/JavierEssay.md)
