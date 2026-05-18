# Kubernetes — Troubleshooting

## Install Minikube and kubectl

Minikube runs a local single-node Kubernetes cluster for development and testing. Install it with:

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

`kubectl` is the command-line tool used to interact with the cluster. Install it with:

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

Verify both are installed correctly:

```bash
minikube version
kubectl version --client
```

If Docker itself is not installed or the daemon is not running, refer to the [Docker Troubleshooting guide](../Containers/DockerTroubleshooting.md) first, as Minikube depends on it.

---

## Minikube fails to start

If `minikube start` fails, check that Docker is running and that your user has permission to use it:

```bash
docker info
```

If this returns a permission error, your user may not be in the `docker` group. Refer to the [Docker Troubleshooting guide](../Containers/DockerTroubleshooting.md) for the fix. If Docker is running but Minikube still fails, try deleting the existing cluster and starting fresh:

```bash
minikube delete
minikube start
```

---

## Pods stuck in Pending

A pod stuck in `Pending` means Kubernetes cannot schedule it onto a node. This is usually caused by insufficient resources on the node. Check the pod events for the specific reason:

```bash
kubectl describe pod <pod-name>
```

Look for a `Warning` event with a message like `Insufficient cpu` or `Insufficient memory`. If this happens in Minikube, the resource requests defined in the manifest may be higher than what the Minikube node has available. Lower the `requests` values in the manifest and reapply:

```bash
kubectl apply -f kubernetes/
```

---

## Pods stuck in CrashLoopBackOff

This means the container is starting, crashing, and being restarted repeatedly. Check the logs of the failing container to identify the error:

```bash
kubectl logs <pod-name>
```

If the container has already restarted, view the logs from the previous instance:

```bash
kubectl logs <pod-name> --previous
```

Common causes are a missing environment variable, a misconfigured ConfigMap reference, or an error in the application code.

---

## Service has no endpoints

If a Service is created but traffic is not reaching any pods, it likely means the selector in the Service does not match the labels on the pods. Check the endpoints assigned to the Service:

```bash
kubectl describe service <service-name>
```

If the `Endpoints` field shows `<none>`, the selector is not matching any pods. Verify that the `selector` in the Service manifest matches the `labels` defined in the pod template of the Deployment exactly, including capitalisation.

---

## Cannot reach Nginx from the host

The Nginx Service uses `NodePort` and is exposed on port 30080 of the Minikube node. Make sure you are using the correct node IP:

```bash
minikube ip
curl http://$(minikube ip):30080
```

If this still does not work, confirm the Nginx pod is running and healthy:

```bash
kubectl get pods -l app=nginx
```

A pod that is running but not yet ready will not receive traffic from the Service until its readiness probe passes.

---

## ConfigMap changes not reflected in pods

Kubernetes does not automatically restart pods when a ConfigMap is updated. After applying changes to the ConfigMap, restart the affected Deployment to force the pods to pick up the new values:

```bash
kubectl apply -f kubernetes/
kubectl rollout restart deployment backend
```

---

## Changes to manifests not taking effect

After editing a manifest file, always reapply it. Kubernetes will compare the new spec against the current state and only update what has changed:

```bash
kubectl apply -f kubernetes/
```

To confirm the current state of a resource matches what you expect:

```bash
kubectl describe deployment <deployment-name>
```
