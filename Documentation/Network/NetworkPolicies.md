# Kubernetes NetworkPolicies

## Overview

Kubernetes NetworkPolicies define which pods can communicate with each other and with external endpoints. Without any NetworkPolicy, all pods in a cluster can reach each other freely regardless of namespace or label — this is the default open behavior Kubernetes ships with. NetworkPolicies change that by explicitly defining what is allowed, with everything else implicitly denied once a policy applies to a pod.

The policies below enforce the segmentation defined in the network design: environments are isolated, the backend is only reachable from Nginx, and no pod has unrestricted external access.

---

## Default Deny

The first policy to apply in any namespace is a default deny-all. This ensures that no traffic is allowed unless a subsequent policy explicitly permits it. Without this baseline, any pod not covered by a more specific policy would still be reachable by everything.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

The empty `podSelector` matches all pods in the namespace. Applying this to development, staging, and production namespaces independently ensures each environment starts from a clean deny-all baseline.

---

## Allow Nginx to reach the backend

Nginx is the only service that should be able to send requests to the backend. This policy allows ingress to the backend pod only from pods labelled `app: nginx`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-nginx-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: nginx
      ports:
        - protocol: TCP
          port: 8080
```

This means even if another pod in the cluster were compromised, it could not directly reach the backend — only traffic coming from a pod with the `app: nginx` label is accepted on port 8080.

---

## Allow Nginx to receive external traffic

Nginx needs to accept incoming traffic from outside the cluster. This policy allows ingress on port 80 from any source.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-to-nginx
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Ingress
  ingress:
    - ports:
        - protocol: TCP
          port: 80
```

---

## Block production from reaching development

This egress policy on production pods prevents any outbound connection to the development namespace. Traffic must never flow backwards through environments.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-production-to-development
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchExpressions:
              - key: kubernetes.io/metadata.name
                operator: NotIn
                values:
                  - development
                  - staging
```

---

## Testing NetworkPolicies

After applying the policies, verify they are working as expected. Open a shell inside a pod and attempt connections that should be blocked:

```bash
# This should succeed — Nginx reaching the backend
kubectl exec -it <nginx-pod> -n production -- wget -qO- http://backend:8080

# This should fail — a development pod trying to reach production
kubectl exec -it <dev-pod> -n development -- wget -qO- http://backend.production.svc.cluster.local:8080
```

A blocked connection will time out rather than return an immediate refusal, since NetworkPolicies drop packets silently. If a connection that should be blocked succeeds, review the policy selectors — a mismatch in labels or namespace names is the most common cause.

---

## Important considerations

NetworkPolicies are enforced by the cluster's network plugin (CNI). Not all CNI plugins support NetworkPolicies — the default Minikube setup may require enabling a compatible plugin such as Calico. Without a supporting CNI, the policies will be created but silently ignored, which is dangerous because it gives a false sense of security.

NetworkPolicies are also namespace-scoped. Policies in one namespace do not affect pods in another unless cross-namespace selectors are explicitly used. Always apply a default-deny policy to every namespace, not just production.