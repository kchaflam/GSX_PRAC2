# Kubernetes NetworkPolicies

## Overview

Kubernetes NetworkPolicies define which pods can communicate with each other and with external endpoints. Without any NetworkPolicy, pods in a cluster can usually reach each other freely regardless of namespace or label. NetworkPolicies change that model by explicitly defining what is allowed.

The policies in `KubernetesPolicies/networkpolicies/` enforce the segmentation defined in the network design across `development`, `staging`, and `production`:

- each namespace starts with default-deny ingress and egress
- Nginx can receive external traffic on port 80
- backend only accepts traffic from Nginx in the same namespace
- Nginx can only send application traffic to the backend in the same namespace
- pods can resolve Kubernetes service names through DNS
- cross-environment traffic is blocked by default

NetworkPolicies are allow-lists, not explicit deny rules. This is important: there is no separate "deny development to production" object. Instead, all traffic is denied first, and only the required flows are added back.

---

## Files Included

| File | Purpose |
| ---- | ------- |
| `KubernetesPolicies/namespaces.yml` | Creates the `development`, `staging`, and `production` namespaces used by the policies |
| `KubernetesPolicies/networkpolicies/default-deny.yml` | Applies default-deny ingress and egress in all three namespaces |
| `KubernetesPolicies/networkpolicies/nginx-external.yml` | Allows external traffic to reach Nginx on port 80 in each namespace |
| `KubernetesPolicies/networkpolicies/nginx-backend.yml` | Allows Nginx to communicate with the backend in the same namespace |
| `KubernetesPolicies/networkpolicies/dns-egress.yml` | Allows pods to query Kubernetes DNS in `kube-system` |

The policies are kept in separate files by responsibility. This makes the intent easier to review: one file creates the baseline, and each additional file adds one controlled exception.

---

## Traffic Matrix

| Source | Destination | Port | Result | Reason |
| ------ | ----------- | ---- | ------ | ------ |
| Internet / host | Nginx in any environment | 80 | Allowed | `allow-external-to-nginx` exposes the web entry point |
| Nginx | Backend in the same namespace | 8080 | Allowed | `allow-nginx-to-backend` and `allow-nginx-egress-to-backend` define the app path |
| Any pod | Kubernetes DNS | 53 TCP/UDP | Allowed | `allow-dns-egress` keeps service discovery working |
| Backend | Internet / other namespaces | Any | Blocked | no egress exception exists for backend |
| Development pod | Production backend | 8080 | Blocked | default-deny egress plus no cross-namespace allow |
| Production pod | Development or staging | Any | Blocked | default-deny egress plus no cross-namespace allow |
| Random pod | Backend in same namespace | 8080 | Blocked | backend only accepts ingress from pods labelled `app: nginx` |

This table is the easiest way to explain the design: the application has exactly one public entry point and exactly one internal application path.

---

## How Selectors Work

NetworkPolicies select pods through labels. Our Deployments label pods with `app: nginx` or `app: backend`, and Terraform also adds an environment label such as `env: prod`.

The most important detail is that `podSelector` is namespace-scoped. A selector like this:

```yaml
podSelector:
  matchLabels:
    app: backend
```

only selects backend pods inside the same namespace as the NetworkPolicy. It does not automatically select backend pods in other namespaces. This is why the same policy pattern is repeated in `development`, `staging`, and `production`.

For cross-namespace references, a policy must use `namespaceSelector`. We only use that for DNS, where application pods need to reach CoreDNS in the `kube-system` namespace.

---

## Default Deny

The first policy applied in every namespace is `default-deny-all`. It selects all pods and denies both ingress and egress unless another policy explicitly allows a flow.

Example for `development`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: development
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

The same policy is applied to `development`, `staging`, and `production`. This creates a secure baseline for every environment.

Without this policy, Kubernetes starts from an open network model and the later allow rules would not provide meaningful isolation. Default-deny is the part that turns the rest of the files into a true allow-list.

---

## Allow External Traffic to Nginx

Nginx is the public entry point for the application, so it needs to accept incoming traffic on port 80. This rule is applied independently in each namespace.

Example for `production`:

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

Only pods labelled `app: nginx` are selected by this rule. The backend is not exposed externally.

This does not expose the backend directly. External clients must enter through Nginx first, which matches the DMZ idea from the network design: public traffic reaches the edge service, and internal services stay private.

---

## Allow Nginx to Reach Backend

Two rules are needed for Nginx to reach the backend when default-deny is enabled:

- backend ingress from Nginx
- Nginx egress to backend

Example for backend ingress:

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

Example for Nginx egress:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-nginx-egress-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: nginx
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: backend
      ports:
        - protocol: TCP
          port: 8080
```

Because both selectors are namespace-scoped, this allows Nginx to reach only the backend in the same namespace. It does not allow development to reach production or production to reach staging.

Both directions are needed because we deny egress as well as ingress. If only backend ingress were allowed, Nginx might still be blocked from sending the request. If only Nginx egress were allowed, the backend would still reject incoming traffic. Together they define the complete allowed flow.

---

## Allow DNS Egress

With egress denied by default, pods also need an exception for DNS. Without this, service names such as `backend` or `backend.production.svc.cluster.local` may not resolve.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

This policy is also applied to all three application namespaces.

The DNS rule is intentionally narrow: it only allows port 53 to pods labelled `k8s-app: kube-dns` in `kube-system`. It does not give pods general internet access.

---

## Cross-environment Isolation

Cross-environment traffic is blocked by the combination of default-deny egress and narrow allow rules. The only egress allowed from application namespaces is:

- DNS to `kube-system`
- Nginx to backend inside the same namespace

This means a pod in `development` cannot directly reach backend pods in `production`, and production pods cannot initiate traffic to development or staging.

This matches the network design principle that promotion between environments should happen through CI/CD and management tooling, not through direct pod-to-pod connections.

---

## Testing NetworkPolicies

Apply the namespace and policy manifests:

```bash
kubectl apply -f KubernetesPolicies/namespaces.yml
kubectl apply -f KubernetesPolicies/networkpolicies/
```

Test an allowed path in production:

```bash
kubectl exec -it <nginx-pod> -n production -- wget -qO- http://backend:8080
```

Test a blocked cross-environment path:

```bash
kubectl exec -it <dev-pod> -n development -- wget -qO- http://backend.production.svc.cluster.local:8080
```

A blocked connection usually times out because NetworkPolicies drop packets silently. If a connection that should be blocked succeeds, check:

- whether the cluster CNI supports NetworkPolicies
- whether the policies were applied to the expected namespace
- whether pod labels match the selectors
- whether the test pod is actually running in the namespace being tested

Useful inspection commands:

```bash
kubectl get networkpolicy -A
kubectl describe networkpolicy default-deny-all -n production
kubectl describe networkpolicy allow-nginx-to-backend -n production
kubectl get pods -A --show-labels
kubectl get namespaces --show-labels
```

To confirm that each namespace has the expected policy set:

```bash
kubectl get networkpolicy -n development
kubectl get networkpolicy -n staging
kubectl get networkpolicy -n production
```

Each namespace should show:

```text
default-deny-all
allow-dns-egress
allow-external-to-nginx
allow-nginx-to-backend
allow-nginx-egress-to-backend
```

---

## Important Considerations

NetworkPolicies are enforced by the cluster network plugin (CNI). Not all CNI plugins support NetworkPolicies. The default Minikube setup may require enabling a compatible plugin such as Calico. Without a supporting CNI, Kubernetes will accept the policy objects but not enforce the traffic rules.

NetworkPolicies are namespace-scoped. A `podSelector` only selects pods inside the namespace where the policy exists unless a `namespaceSelector` is used. This is why the same policy pattern is repeated for `development`, `staging`, and `production`.

Another important limitation is that NetworkPolicies control pod network traffic, not user permissions. They do not replace Kubernetes RBAC, Secrets management, authentication, or application-level authorization. They are one security layer in a defense-in-depth design.
