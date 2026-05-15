# Kubernetes — Scaling & Resilience

## Overview

One of the main reasons to use Kubernetes over Docker Compose is its ability to run multiple identical copies of a service and recover automatically from failures. This document covers how to scale deployments up and down, what to observe during the process, and how to verify that Kubernetes restarts pods when they are deleted or crash.

---

## Scaling

Kubernetes allows changing the number of running replicas of a Deployment at any time without downtime. The Service in front of the pods automatically updates its list of endpoints as pods are added or removed, so traffic is always distributed across whatever pods are currently healthy and ready.

Scale the Nginx Deployment up to 3 replicas:

```bash
kubectl scale deployment nginx --replicas=3
```

Watch the pods being created in real time. New pods will go through `Pending` → `ContainerCreating` → `Running` as Kubernetes pulls the image and starts the containers:

```bash
kubectl get pods --watch
```

Once all three pods are running, confirm the Service has picked them all up as endpoints:

```bash
kubectl describe service nginx
```

The `Endpoints` field should list all three pod IPs. Any request to the Service will now be load-balanced across them.

Scale back down to a single replica. Kubernetes will terminate the extra pods gracefully, waiting for in-flight requests to complete before stopping them:

```bash
kubectl scale deployment nginx --replicas=1
```

Watch the pods terminate and confirm only one remains:

```bash
kubectl get pods --watch
```

---

## Resilience

Kubernetes continuously compares the running state of the cluster against what the Deployment manifest defines. If the number of running pods drops below the specified replica count — whether due to a crash, a manual deletion, or a node failure — Kubernetes automatically starts a new pod to replace it.

Get the name of the running Nginx pod:

```bash
kubectl get pods -l app=nginx
```

Delete the pod to simulate a failure:

```bash
kubectl delete pod <pod-name>
```

Watch Kubernetes detect the missing pod and immediately start a replacement. The old pod will show as `Terminating` while the new one goes through `ContainerCreating` → `Running`:

```bash
kubectl get pods --watch
```

The replacement pod will have a different name, as Kubernetes generates a new identifier for each pod it creates. The Service will briefly have no healthy endpoints during the few seconds it takes for the new pod to pass its readiness probe, after which traffic resumes normally.

This behaviour demonstrates why running a pod directly without a Deployment is not suitable for anything that needs to stay available — a standalone pod that is deleted or crashes simply disappears and is never replaced.

---

## Observing pod logs after a restart

When a pod is replaced, the logs from the previous instance are no longer accessible through the pod name since the pod itself no longer exists. To view the logs of the current running pod:

```bash
kubectl logs <new-pod-name>
```

To see the logs from the previous instance of a container within the same pod (useful when a container has restarted due to a failed liveness probe):

```bash
kubectl logs <pod-name> --previous
```