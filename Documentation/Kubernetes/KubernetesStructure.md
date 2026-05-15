# Kubernetes — Documentation

## Overview

Kubernetes manages the deployment, scaling, and availability of containerized applications. Unlike Docker Compose, which runs containers on a single host, Kubernetes is designed for environments where reliability and automated recovery matter.

This setup deploys Nginx and the Python backend onto a local cluster running on Minikube. Each service is defined through manifest files that describe the desired state — Kubernetes then does the work of making sure the cluster matches that state at all times.

---

## Resources

### Deployment

A Deployment is how you run containers in Kubernetes. It defines how many replicas should run, which image to use, and what to do when a pod fails. Kubernetes monitors the running pods and automatically replaces any that stop matching the spec.

Running a pod directly without a Deployment is possible but means no automatic restarts and no scaling. Both services here use Deployments for exactly that reason — a pod that crashes without one is simply gone. Both start with one replica and can be scaled up at any time without changing the manifest.

### Service

Pods are ephemeral and get a new IP every time they are replaced, so you cannot reliably address them directly. A Service sits in front of the pods, provides a stable DNS name, and load-balances traffic across all healthy pods matching its selector.

The backend uses `ClusterIP`, making it reachable only from inside the cluster at `http://backend:8080`. Exposing it externally is unnecessary since only Nginx needs to reach it, and doing so would be an avoidable attack surface. Nginx uses `NodePort` on port 30080, which is how external traffic reaches it in a local Minikube setup.

### ConfigMap

A ConfigMap holds non-sensitive configuration as key-value pairs and injects them into pods as environment variables. The alternative — hardcoding values in the image or the manifest — means rebuilding or editing files every time something changes.

Here it stores the `PORT` value for the backend. The Deployment reads it via `configMapKeyRef`, so changing the port only requires updating the ConfigMap and restarting the pod. It is worth noting that ConfigMaps are not suitable for sensitive data — passwords, tokens, and API keys should use a `Secret` instead, since anything stored in a ConfigMap is readable by anyone with access to the cluster namespace.

---

## Probes

Without probes, Kubernetes cannot tell whether an application inside a running container is actually working. A container can be running while the app inside it is still starting up, stuck, or broken — and Kubernetes will keep sending traffic to it anyway.

### Readiness Probe

Checks whether the pod is ready to receive traffic. Until it passes, the pod is excluded from the Service's endpoints. Both services use an HTTP GET to `/`. Without this, requests made during the startup window would hit a pod that is not ready yet and fail.

| Setting       | Nginx | Backend |
| ------------- | ----- | ------- |
| Initial delay | 2s    | 3s      |
| Period        | 5s    | 5s      |

### Liveness Probe

Checks whether the application is still working after startup. If it fails, Kubernetes restarts the container — useful for catching deadlocks or frozen processes that have not crashed outright. The initial delay is longer than the readiness probe to give the application time to fully start before Kubernetes begins checking whether it needs to be restarted. Setting this delay too low risks creating a restart loop where Kubernetes kills a container that is still initializing.

| Setting       | Nginx | Backend |
| ------------- | ----- | ------- |
| Initial delay | 5s    | 10s     |
| Period        | 10s   | 10s     |

---

## Resource Limits

Without resource limits, a container can consume all available CPU and memory on the node, affecting everything else running on it. Requests tell the scheduler the minimum a pod needs to be placed on a node; limits are the hard ceiling.

|         | CPU Request | CPU Limit | Memory Request | Memory Limit |
| ------- | ----------- | --------- | -------------- | ------------ |
| Nginx   | 50m         | 200m      | 64Mi           | 128Mi        |
| Backend | 100m        | 250m      | 128Mi          | 256Mi        |

The backend gets more resources since it handles application logic and file I/O, while Nginx only serves static files. These values are conservative for a local Minikube setup and should be adjusted based on observed usage in production. Setting limits too low can cause containers to be throttled or killed unexpectedly — if a pod keeps restarting without an obvious reason, an exceeded memory limit is worth checking first with `kubectl describe pod`.

---

## Storage

The backend mounts an `emptyDir` volume at `/data` for its log file. This volume exists as long as the pod does and is lost when the pod is replaced. `emptyDir` was chosen over a `PersistentVolumeClaim` to keep the setup simple — it is enough to demonstrate volume mounting and the logging mechanism without the added complexity of persistent storage provisioning in Minikube. In production, any data that needs to survive pod replacements should use a `PersistentVolumeClaim` instead.
