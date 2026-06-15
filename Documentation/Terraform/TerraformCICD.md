# CI/CD Pipeline

## Overview

The pipeline is split into two distinct parts. CI runs automatically on GitHub Actions on every push to `main` and is responsible for building and validating. CD is run manually on the local machine and is responsible for actually deploying to the Minikube cluster.

This split exists because GitHub Actions runners are hosted by GitHub and have no access to the local Minikube cluster. Running `terraform apply` from the pipeline would have nowhere to connect to. Instead, the pipeline ensures that the code and images are always in a valid, deployable state, and the local deploy step uses the artifacts it produces.

---

## CI Workflow

The pipeline triggers on every push to `main` and runs the following steps in order:

**1. Checkout** — the repository is cloned onto the runner so the rest of the steps have access to the code.

**2. Docker Buildx setup** — sets up the Docker build environment on the runner, enabling multi-platform builds if needed.

**3. DockerHub login** — authenticates to Docker Hub using credentials stored as GitHub repository secrets (`DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`). These are never exposed in the workflow file or logs.

**4. Build and push backend image** — builds the backend Docker image from `./Containers/Python` and pushes it to Docker Hub tagged with the commit SHA:

```
<dockerhub_user>/backend-gsx:<github.sha>
```

**5. Build and push Nginx image** — same as above for the Nginx image from `./Containers/Nginx`:

```
<dockerhub_user>/nginx-gsx:<github.sha>
```

**6. Terraform format check** — runs `terraform fmt -check` to verify the Terraform files are correctly formatted. The pipeline fails if any file is not formatted, enforcing consistent style across the codebase.

**7. Terraform init** — runs `terraform init -backend=false` to initialize the Terraform working directory and download the provider without connecting to any backend or cluster.

**8. Terraform validate** — runs `terraform validate` to check that the configuration is syntactically correct and internally consistent. This catches errors in resource definitions without needing a live cluster.

---

## Image tagging strategy

Every image pushed by CI is tagged with the full Git commit SHA (`github.sha`). This provides a unique, traceable identifier for every build — you always know exactly which commit produced a given image.

Using `latest` as the only tag would make it impossible to know what is actually running in the cluster or to roll back to a previous version. With SHA tags, deploying a specific version or rolling back is as simple as passing the corresponding SHA to Terraform.

---

## Local Deployment Workflow

Once the CI pipeline passes, the deployment to Minikube is done manually on the local machine:

1. Confirm the CI run is green and note the commit SHA from the GitHub Actions run.

2. Make sure Minikube is running:

```bash
minikube start
```

3. Deploy using Terraform with the SHA tag produced by CI:

```bash
cd Terraform
terraform apply -var="backend_image=<dockerhub_user>/backend-gsx:<SHA>" -var="nginx_image=<dockerhub_user>/nginx-gsx:<SHA>"
```

4. Verify the updated pods are running the correct image:

```bash
kubectl get pods -A
kubectl describe pod <pod-name> -n <namespace> | grep Image
```

---

## Secrets management

The pipeline uses two GitHub repository secrets that must be configured before the workflow can run:

| Secret               | Description                                        |
| -------------------- | -------------------------------------------------- |
| `DOCKERHUB_USERNAME` | Docker Hub username                                |
| `DOCKERHUB_TOKEN`    | Docker Hub access token (not the account password) |

These are set in the repository under **Settings → Secrets and variables → Actions**. They are injected into the workflow at runtime and are never visible in logs or the workflow file.
