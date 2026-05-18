# Terraform — Deploy & Verify

## Prerequisites

Minikube must be running and kubectl must be configured before deploying with Terraform. If they are not set up, refer to the [Kubernetes Troubleshooting guide](../Kubernetes/KubernetesTroubleshooting.md). Terraform must also be installed — if it is missing, refer to the [Terraform Troubleshooting guide](TerraformTroubleshooting.md).

---

## Deploy

All commands are run from the `terraform/` directory.

Initialize Terraform. This downloads the Kubernetes provider and sets up the working directory. It only needs to be run once, or again if the provider requirements change:

```bash
terraform init
```

Preview what Terraform will create or modify without making any changes. Always review the plan before applying to catch unexpected changes:

```bash
terraform plan
```

To deploy with a specific image tag produced by CI, pass the image variables at apply time. Replace `<SHA>` with the commit SHA from the CI run:

```bash
terraform apply -var="backend_image=kchaflam/backend-gsx:<SHA>" -var="nginx_image=kchaflam/nginx-gsx:<SHA>"
```

Terraform will print the planned changes and ask for confirmation before applying. Type `yes` to proceed.

---

## Verify

After a successful apply, Terraform prints the outputs including the assigned NodePort for Nginx. Use it to reach the service:

```bash
curl http://$(minikube ip):<node_port>
```

Confirm all pods are running:

```bash
kubectl get pods
```

Confirm the Services and ConfigMap were created correctly:

```bash
kubectl get services
kubectl get configmap app-config -o yaml
```

---

## Update

To deploy a new image version, run apply again with the new tag. Terraform will detect that only the image has changed and update only the affected Deployment:

```bash
terraform apply -var="backend_image=kchaflam/backend-gsx:<new_SHA>" -var="nginx_image=kchaflam/nginx-gsx:<new_SHA>"
```

---

## Destroy

To remove all resources created by Terraform from the cluster:

```bash
terraform destroy
```

Terraform will list everything it will delete and ask for confirmation. This is the clean way to tear down the stack — it ensures nothing is left behind in the cluster.
