# Kubernetes — Setup, Deploy & Test

## Prerequisites

Docker must be installed and running before starting Minikube, as it is used as the container runtime. Minikube and kubectl must also be installed. If any of these are missing or not working correctly, refer to the [Kubernetes Troubleshooting guide](KubernetesTroubleshooting.md).

---

## Start the Cluster

Start a local Minikube cluster. Minikube will automatically detect the available driver, so no flags are needed in most cases:

```bash
minikube start
```

Confirm the cluster is up and kubectl is connected to it:

```bash
kubectl cluster-info
```

---

## Deploy

From the directory containing the manifest files, apply all of them at once. `kubectl apply -f` reads each manifest and creates or updates the corresponding resources in the cluster — Kubernetes then works to match the running state to what the files describe:

```bash
kubectl apply -f Kubernetes/
```

These raw manifests deploy into the default namespace and expose Nginx on the fixed NodePort `30080`. The Terraform deployment is the recommended full deployment path and creates separate `development`, `staging`, and `production` namespaces with dynamically assigned NodePorts.

Verify all pods are running. It may take a few seconds for them to reach the `Running` state while the images are pulled and the containers start:

```bash
kubectl get pods
```

Check that the Services have been created and have endpoints assigned:

```bash
kubectl get services
```

Confirm the ConfigMap has been created and contains the expected values:

```bash
kubectl get configmap app-config -o yaml
```

---

## Test

Once all pods show as `Running` and `Ready`, retrieve the Minikube node IP to access Nginx from the host:

```bash
minikube ip
```

The Nginx service is exposed on port 30080, so send a request to it using the node IP:

```bash
curl http://$(minikube ip):30080
```

Verify the backend is reachable. Since it uses `ClusterIP` it is not exposed externally, so use `kubectl port-forward` to temporarily forward a local port to the service and test it from the host:

```bash
kubectl port-forward service/backend 8080:8080
curl localhost:8080
```

Once done, press `Ctrl+C` to stop the port forward.

### Service-to-service communication

To verify that Nginx can reach the backend through Kubernetes' internal DNS, open a shell inside the Nginx pod and send a request using the backend service name:

```bash
kubectl exec -it $(kubectl get pod -l app=nginx -o jsonpath='{.items[0].metadata.name}') -- sh
wget -qO- http://backend:8080
```

A successful response confirms that internal DNS resolution is working and that the Service selector is correctly matching the backend pods.

---

## Useful commands

These commands are helpful for inspecting the state of the cluster at any point, not just during initial setup.

Check detailed information about a specific pod, including events and error messages. This is usually the first place to look when a pod is not behaving as expected:

```bash
kubectl describe pod <pod-name>
```

View the logs of a running pod:

```bash
kubectl logs <pod-name>
```

List all resources in the cluster at once — pods, services, deployments and more:

```bash
kubectl get all
```

---

## Stop the Cluster

To stop the Minikube cluster without deleting it, preserving its state for the next time it is started:

```bash
minikube stop
```

To delete the cluster entirely and free up all resources. The next `minikube start` will create a fresh cluster from scratch:

```bash
minikube delete
```
