# Terraform — Deploy & Verify

## Prerequisites

Minikube must be running and kubectl must be configured before deploying with Terraform. If they are not set up, refer to the [Kubernetes Troubleshooting guide](../Kubernetes/KubernetesTroubleshooting.md). Terraform must also be installed — if it is missing, refer to the [Terraform Troubleshooting guide](TerraformTroubleshooting.md).

---

## Deploy

All commands are run from the `Terraform/` directory.

By default, Terraform deploys the same stack into three Kubernetes namespaces:

- `development`
- `staging`
- `production`

The environment list comes from the `environments` variable. The default map is defined in `variables.tf`, and `environments.tfvars.example` shows the same structure as an external tfvars file.

Initialize Terraform. This downloads the Kubernetes provider and sets up the working directory. It only needs to be run once, or again if the provider requirements change:

```bash
terraform init
```

Preview what Terraform will create or modify without making any changes. Always review the plan before applying to catch unexpected changes:

```bash
terraform plan
```

To review the plan with an explicit environment file:

```bash
terraform plan -var-file="environments.tfvars"
```

To deploy with a specific image tag produced by CI, pass the image variables at apply time. Replace `<dockerhub_user>` with the Docker Hub user configured in the GitHub Actions secrets and `<SHA>` with the commit SHA from the CI run:

```bash
terraform apply -var="backend_image=<dockerhub_user>/backend-gsx:<SHA>" -var="nginx_image=<dockerhub_user>/nginx-gsx:<SHA>"
```

Terraform will print the planned changes and ask for confirmation before applying. Type `yes` to proceed.

---

## Verify

After a successful apply, Terraform prints the outputs including the assigned NodePorts for Nginx in each environment. Use the port for the environment you want to test:

```bash
curl http://$(minikube ip):<environment_node_port>
```

Confirm all pods are running:

```bash
kubectl get pods -A
```

Confirm the Services and ConfigMap were created correctly:

```bash
kubectl get services -n development
kubectl get services -n staging
kubectl get services -n production
kubectl get configmap app-config -n production -o yaml
```

### Validate staging before production

Use the same image tag in every environment. The image should be built once, tagged with the commit SHA, and then promoted through the environments without rebuilding it. This ensures staging tests the exact artifact that production will use.

Recommended validation order:

1. Confirm `development` pods and services are healthy.
2. Test the application path in `development`.
3. Confirm `staging` pods and services are healthy.
4. Test Nginx and backend communication in `staging`.
5. Apply or verify NetworkPolicies.
6. Only after staging passes, validate the `production` NodePort and production backend.

Useful commands:

```bash
kubectl get pods -n staging
kubectl get services -n staging
kubectl exec -it <staging-nginx-pod> -n staging -- wget -qO- http://backend:8080
terraform output nginx_node_ports
```

If staging fails, do not use the production endpoint. Fix the code or configuration, build a new image tag, and repeat the promotion flow with the new SHA.

---

## Update

To deploy a new image version, run apply again with the new tag. Terraform will detect that only the image has changed and update only the affected Deployment:

```bash
terraform apply -var="backend_image=<dockerhub_user>/backend-gsx:<new_SHA>" -var="nginx_image=<dockerhub_user>/nginx-gsx:<new_SHA>"
```

---

## Destroy

To remove all resources created by Terraform from the cluster, including the environment namespaces:

```bash
terraform destroy
```

Terraform will list everything it will delete and ask for confirmation. This is the clean way to tear down the stack — it ensures nothing is left behind in the cluster.
