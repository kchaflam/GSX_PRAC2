# Terraform Resource Guide

## Overview

Terraform is an Infrastructure as Code tool that lets you define infrastructure declaratively — you describe the desired end state and Terraform figures out how to get there. This is the key difference from a procedural tool like Ansible, where you write the steps to execute in order. With Terraform you don't say "create this deployment then create this service" — you say "I want a deployment and a service to exist" and it handles the rest.

The operational benefit is that Terraform tracks the current state of the infrastructure and only applies what needs to change. Running it twice with no changes does nothing. If the cluster is wiped, a single `terraform apply` reproduces it exactly. This makes the setup fully version-controlled and reproducible by anyone with access to the repo and a running cluster.

---

## File Structure

The configuration is split by responsibility rather than keeping everything in one file. One big file works but quickly becomes hard to read — splitting by resource type makes it clear where to look for each part of the setup.

- `main.tf` — provider configuration and Terraform version constraints
- `namespaces.tf` — Kubernetes namespaces for each environment
- `deployment.tf` — Deployment resources for Nginx and the backend
- `services.tf` — Service resources for both applications
- `configmap.tf` — ConfigMap holding the backend port configuration
- `variables.tf` — input variable definitions with defaults
- `environments.tfvars.example` — example environment map that can be passed with `-var-file`
- `outputs.tf` — values printed after a successful apply

---

## Provider

The Kubernetes provider connects to the cluster using the local kubeconfig at `~/.kube/config`, which is the same file kubectl uses. This means Terraform always talks to whatever cluster kubectl is currently pointed at — in this case Minikube. No credentials are hardcoded anywhere in the configuration, which is important: hardcoding cluster credentials in a file that gets committed to a repository is a serious security risk.

---

## Variables

Variables cover anything that might change between runs or environments — mainly the image references and ports. This avoids hardcoded values scattered across resource files and makes the configuration easy to override at deploy time.

| Variable | Description | Default |
|----------|-------------|---------|
| `backend_image` | Full image reference for the backend | `kchaflam/backend-gsx:latest` |
| `nginx_image` | Full image reference for Nginx | `kchaflam/nginx-gsx:latest` |
| `backend_port` | Port the backend listens on | `8080` |
| `nginx_port` | Port Nginx listens on | `80` |
| `environments` | Environment names, namespaces and labels | `dev`, `staging`, `prod` |

The image variables default to `latest`, which is fine for quick local testing but should never be used for a real deployment. The `latest` tag gives no indication of what is actually running — it gets overwritten on every push and makes rollbacks impossible. In practice these are always overridden at apply time with the specific SHA tag produced by CI.

---

## Multiple Environments

The `environments` variable defines the environment map used by Terraform. By default it contains:

- `dev` -> namespace `development`
- `staging` -> namespace `staging`
- `prod` -> namespace `production`

All Kubernetes resources use `for_each = var.environments`, so the same Terraform code creates one copy of each resource per environment. This is how the stack is deployed to multiple environments with one codebase instead of maintaining separate Terraform files for dev, staging, and production.

The default values live in `variables.tf`. If the environment list needs to be changed, copy `environments.tfvars.example` and pass it explicitly:

```bash
cp environments.tfvars.example environments.tfvars
terraform apply -var-file="environments.tfvars"
```

Using a tfvars file keeps environment-specific values outside the resource definitions. The resource files stay reusable, while the environment map can be adjusted for local testing or future deployments.

---

## Resources

### Namespaces

Terraform creates three separate namespaces: `development`, `staging`, and `production`. Each environment receives its own copy of the ConfigMap, Deployments, and Services. This keeps the environments isolated while still using the same reusable Terraform code through `for_each`.

### ConfigMap

Stores the `PORT` value for the backend in each namespace. The Deployment reads it directly via `config_map_key_ref`, so the value flows from the Terraform variable into the ConfigMap and from there into the container as an environment variable. This keeps configuration centralized and avoids duplicating values across files — if the port needs to change, it changes in one place.

### Deployments

Both services run as Deployments with one replica per environment. The image for each is driven by an input variable, which is how the SHA tag from CI gets injected at deploy time without touching the resource definition. The backend also mounts an `emptyDir` volume at `/data` for its log file. This is intentionally not persistent and is documented in the Kubernetes resource guide. Both deployments include resource requests, limits, readiness probes, and liveness probes so the Terraform deployment keeps the same operational behavior as the raw Kubernetes manifests.

### Services

The backend uses `ClusterIP`, keeping it internal to its namespace. There is no reason to expose it externally since only Nginx needs to reach it, and exposing it unnecessarily increases the attack surface. Nginx uses `NodePort` to accept external traffic. The node port is not hardcoded — after the problems caused by specifying fixed values, Kubernetes now assigns ports automatically from the 30000-32767 range. The assigned ports are available as an output per environment so you always know where to reach each Nginx service after a deploy.

---

## Outputs

Terraform prints these values after a successful apply:

| Output | Description |
|--------|-------------|
| `backend_service` | Backend Service names by environment |
| `nginx_service` | Nginx Service names by environment |
| `nginx_node_ports` | Assigned NodePorts for the Nginx Services by environment |

The `nginx_node_ports` output is the most useful one in practice. Since the ports are assigned dynamically, without this output you would have to run `kubectl get service nginx -n <namespace>` for each environment to find out where Nginx is reachable.
