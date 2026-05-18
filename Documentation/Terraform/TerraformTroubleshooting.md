# Terraform — Troubleshooting

## Terraform is not installed

If `terraform` returns `command not found`, download and install the latest version:

```bash
wget -O terraform.zip https://releases.hashicorp.com/terraform/$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)/terraform_$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)_linux_amd64.zip
unzip terraform.zip
sudo mv terraform /usr/local/bin/
```

Verify the installation:

```bash
terraform version
```

---

## Provider not initialized

If Terraform returns an error about a missing provider or asks you to run `terraform init`, the working directory has not been initialized yet. Run:

```bash
terraform init
```

This only needs to be done once per working directory, or again if the provider version requirements change.

---

## Cannot connect to the cluster

If `terraform apply` fails with a connection error, Terraform cannot reach the Kubernetes cluster. Make sure Minikube is running and kubectl is pointing to it:

```bash
minikube status
kubectl cluster-info
```

If Minikube is not running, start it:

```bash
minikube start
```

---

## Resource already exists

If apply fails saying a resource already exists, it may have been created manually or by a previous apply that was not tracked by Terraform. Import the existing resource into the Terraform state so it can manage it:

```bash
terraform import kubernetes_deployment.backend default/backend
```

Alternatively, delete the resource manually and let Terraform recreate it:

```bash
kubectl delete deployment backend
terraform apply
```

---

## Terraform state out of sync

If the cluster state does not match what Terraform expects — for example after manually editing resources with `kubectl` — refresh the state to bring it up to date:

```bash
terraform refresh
```

Then run `terraform plan` to see what differences remain and decide whether to apply them or adjust the manifests.

---

## Terraform fmt check failing in CI

If the CI pipeline fails on the format check step, one or more Terraform files are not correctly formatted. Fix them locally and commit:

```bash
cd terraform
terraform fmt
git add .
git commit -m "fix: terraform format"
git push
```

---

## Terraform validate failing in CI

If `terraform validate` fails, there is a syntax or configuration error in the Terraform files. Run validate locally to see the full error message:

```bash
cd terraform
terraform init -backend=false
terraform validate
```

Fix the reported error, commit and push again.

---

## CI pipeline fails to push to Docker Hub

If the build or push steps fail with an authentication error, the GitHub secrets may be missing or incorrect. Verify that `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are set correctly under **Settings → Secrets and variables → Actions** in the repository. Make sure the token has write permissions for the repositories being pushed to.
