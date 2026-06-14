# Full Integration Test & Operational Runbook

## Purpose

This document describes how to verify the complete infrastructure from a clean state. It connects the work from Docker, Docker Compose, Kubernetes, Terraform, CI/CD, and NetworkPolicies into one operational procedure.

The expected final state is:

- Docker images are built and pushed by GitHub Actions.
- Terraform deploys the application into `development`, `staging`, and `production` namespaces.
- Nginx is externally reachable through a NodePort in each environment.
- The backend remains internal and is reached through the Kubernetes Service.
- Resource limits, readiness probes, liveness probes, and the backend `/data` volume are present.
- NetworkPolicies can be applied to enforce segmentation, especially around production.

Prometheus and Grafana are not included in this delivery. Observability is handled at this level through Kubernetes health probes, service status, pod logs, resource descriptions, and CI validation.

---

## 1. Start from a clean state

Start Minikube and remove any previous Terraform-managed deployment:

```bash
minikube start
cd Terraform
terraform init
terraform destroy
```

If the cluster should be completely reset, delete and recreate Minikube:

```bash
minikube delete
minikube start
```

Verify that old application resources are gone:

```bash
kubectl get namespaces
kubectl get pods -A
```

---

## 2. Confirm CI artifacts

Push the latest commit to `main` and wait for the GitHub Actions pipeline to finish successfully. The pipeline must:

- Build `backend-gsx:<SHA>` from `Containers/Python`
- Build `nginx-gsx:<SHA>` from `Containers/Nginx`
- Push both images to Docker Hub
- Run `terraform fmt -check`
- Run `terraform init -backend=false`
- Run `terraform validate`

The Docker Hub repositories must match the names used by Terraform:

```text
<dockerhub_user>/backend-gsx:<SHA>
<dockerhub_user>/nginx-gsx:<SHA>
```

---

## 3. Deploy from Terraform

Deploy the infrastructure using the image tag created by CI. Replace `<dockerhub_user>` and `<SHA>` with the values from the successful CI run:

```bash
cd Terraform
terraform apply `
  -var="backend_image=<dockerhub_user>/backend-gsx:<SHA>" `
  -var="nginx_image=<dockerhub_user>/nginx-gsx:<SHA>"
```

Terraform creates:

- Namespaces: `development`, `staging`, `production`
- One backend Deployment per environment
- One Nginx Deployment per environment
- One backend ClusterIP Service per environment
- One Nginx NodePort Service per environment
- One ConfigMap per environment

The apply should finish in a few minutes on a local Minikube cluster, depending mostly on image pull time.

---

## 4. Verify the deployment

Confirm all pods are running:

```bash
kubectl get pods -A
```

Confirm the services exist in each environment:

```bash
kubectl get services -n development
kubectl get services -n staging
kubectl get services -n production
```

Read the Terraform outputs and test one exposed Nginx service:

```bash
terraform output nginx_node_ports
curl http://$(minikube ip):<environment_node_port>
```

Verify the backend is internal by using port-forwarding:

```bash
kubectl port-forward service/backend 8080:8080 -n production
curl localhost:8080
curl localhost:8080/logs
```

Stop the port-forward with `Ctrl+C`.

---

## 5. Verify service-to-service communication

Open a shell in the production Nginx pod and call the backend through the Kubernetes Service name:

```bash
kubectl exec -it <nginx-pod> -n production -- sh
wget -qO- http://backend:8080
```

The expected response is:

```text
Backend is running!
```

This confirms that internal DNS, Service selectors, and pod labels are working.

---

## 6. Verify health and resilience

Check that probes are configured:

```bash
kubectl describe deployment nginx -n production
kubectl describe deployment backend -n production
```

Scale Nginx to three replicas:

```bash
kubectl scale deployment nginx --replicas=3 -n production
kubectl get pods -n production -w
```

Delete one pod and verify Kubernetes replaces it:

```bash
kubectl delete pod <nginx-pod> -n production
kubectl get pods -n production -w
```

Scale back down:

```bash
kubectl scale deployment nginx --replicas=1 -n production
```

---

## 7. Apply and test NetworkPolicies

Apply the namespace and policy manifests:

```bash
kubectl apply -f KubernetesPolicies/namespaces.yml
kubectl apply -f KubernetesPolicies/networkpolicies/
```

Test an allowed path:

```bash
kubectl exec -it <nginx-pod> -n production -- wget -qO- http://backend:8080
```

Test a blocked path, for example a development pod attempting to reach production:

```bash
kubectl exec -it <dev-pod> -n development -- wget -qO- http://backend.production.svc.cluster.local:8080
```

A blocked connection usually times out. NetworkPolicies require a CNI plugin that supports them, such as Calico; otherwise Kubernetes will accept the policy objects but not enforce the traffic rules.

---

## 8. Troubleshooting checklist

If a pod is not starting:

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

If a Service has no endpoints:

```bash
kubectl describe service <service-name> -n <namespace>
kubectl get pods -n <namespace> --show-labels
```

If the image cannot be pulled:

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Check that the image name matches the Docker Hub repository and commit SHA produced by CI.

If Terraform fails:

```bash
terraform fmt
terraform validate
terraform plan
```

---

## Evidence to capture for final delivery

Recommended screenshots or terminal captures:

- Successful GitHub Actions run
- Docker Hub showing `backend-gsx` and `nginx-gsx` images with SHA tags
- `terraform apply` completing successfully
- `terraform output nginx_node_ports`
- `kubectl get pods -A`
- `kubectl get services -n production`
- Browser or `curl` result against the Nginx NodePort
- Backend `/logs` endpoint through port-forward
- NetworkPolicy test showing allowed and blocked traffic
