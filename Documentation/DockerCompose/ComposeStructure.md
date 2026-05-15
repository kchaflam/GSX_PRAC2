# Docker Compose — Documentation

## Overview

This Compose setup defines a multi-container application consisting of two services: an Nginx web server and a Python backend. Both are built from local Dockerfiles. The stack is configured through environment variables, includes persistent storage for the backend, and has health checks and restart policies to keep services running reliably.

The main motivation for using Docker Compose here is to avoid managing each container manually with individual `docker run` commands. As soon as more than one container needs to work together, doing it by hand becomes error-prone: ports, network connections, volumes and startup order all need to be coordinated. Compose centralizes all of that in a single file, making the setup reproducible and easy to bring up or tear down in one command.

---

## Services

### Nginx

Nginx acts as the frontend of the stack, serving the static HTML content to the outside world. It is built directly from the local Dockerfile rather than using a pre-built image, which ensures that any change to the static content or the Dockerfile is always reflected when the stack is rebuilt.

Nginx is configured to depend on the backend being healthy before it starts. This is important because if Nginx were to start first and immediately receive a request that requires the backend to be up, it would fail. The dependency ensures the stack comes up in a predictable order.

The port exposed on the host is controlled by an environment variable, which means it can be changed without touching the Compose file — useful when the default port is already occupied on a given machine.

### Backend

The backend is a Python HTTP server responsible for handling application logic and writing persistent logs. Like Nginx, it is built from a local Dockerfile so the image always reflects the current state of the code.

The backend exposes its port both to the host (for direct testing) and to other services within the Compose network. The port is passed in as an environment variable at runtime, which avoids hardcoding it in the application code and makes it easy to reconfigure without rebuilding the image.

The backend is the only service that writes data to a persistent volume, which is why it is the only one with a volume mount. Nginx serves static files baked into the image and has no need for persistent storage.

---

## Networking

Compose automatically creates a default bridge network and connects all services to it. This means services can reach each other using their service name as the hostname without any additional configuration — Nginx can send requests to `http://backend:8080` and Docker's internal DNS resolves the name to the correct container IP.

The alternative would be to manage networking manually, either by running containers on the host network or by linking them explicitly. Both approaches are fragile and do not scale well. The Compose default network provides isolation (the services are not reachable from outside unless a port is explicitly published) while keeping internal communication simple.

One thing to be aware of is that this default network places all services in the same network segment. For a two-service setup this is fine, but in larger stacks it can be worth defining separate networks to restrict which services can talk to each other and reduce the blast radius of a compromised container.

---

## Volumes

A named volume `app_data` is mounted to the `/data` directory inside the backend container. This is where the application writes its log file on every startup and appends entries over time.

Using a named volume rather than a bind mount was a deliberate choice. A bind mount ties the data to a specific path on the host filesystem, which creates a dependency on the host's directory structure and can cause permission issues across different machines. A named volume is managed entirely by Docker, is portable, and survives `docker-compose down` without any special flags. The data is only removed if the volume is explicitly deleted with `docker-compose down -v` or `docker volume rm`.

The risk of not having a volume here would be data loss on every container restart. Since the backend logs container start times, losing the volume would mean losing the history of when the service was started, which defeats the purpose of the logging mechanism.

---

## Configuration

All configurable values are defined in a `.env` file placed in the same directory as `docker-compose.yml`. Compose reads this file automatically at startup and substitutes the variables throughout the configuration. This means the Compose file itself contains no hardcoded values and can be committed to the repository safely.

| Variable                | Description                                      | Default |
| ----------------------- | ------------------------------------------------ | ------- |
| `NGINX_PORT`            | Host port mapped to Nginx                        | `80`    |
| `NGINX_INTERNAL_PORT`   | Port Nginx listens on inside the container       | `80`    |
| `BACKEND_PORT`          | Host port mapped to the backend                  | `8080`  |
| `BACKEND_INTERNAL_PORT` | Port the backend listens on inside the container | `8080`  |

The separation between host port and internal port exists for flexibility. The internal port is what the application actually listens on inside the container and should generally stay fixed. The host port is what gets exposed on the machine running Docker and can be changed freely to avoid conflicts with other services.

The `.env` file must never be committed to the repository if it contains real credentials, API keys, or passwords. In this case the values are just port numbers, but the pattern still matters: committing a `.env` file with secrets is one of the most common causes of credential leaks in version-controlled projects. An `.env.example` file with placeholder values should be provided instead so that anyone cloning the repository knows what variables are needed without exposing real values.

---

## Health Checks

Both services define a health check that periodically sends an HTTP request to confirm the service is actually responding, not just running as a process. A container can be in a running state while the application inside it is still starting up, has crashed, or is stuck — the health check catches these situations.

| Setting  | Value |
| -------- | ----- |
| Interval | 60s   |
| Timeout  | 10s   |
| Retries  | 3     |

The interval of 60 seconds means Docker checks the service once per minute. The timeout of 10 seconds gives the service enough time to respond under normal load before the check is considered failed. After 3 consecutive failures, the container is marked as unhealthy.

The `depends_on` directive on Nginx references this health status, so Nginx will not start until the backend has passed at least one health check. Without this, Nginx could start while the backend is still initializing, leading to failed requests during the startup window.

---

## Restart Policy

Both services use `restart: always`, which instructs Docker to automatically restart a container if it stops for any reason — whether due to a crash, an unhandled exception, or a host reboot. This is appropriate for services that are expected to run continuously and where downtime should be minimized without manual intervention.

The main trade-off is that `restart: always` will also restart a container that is failing repeatedly, potentially creating a restart loop if there is a configuration error or a bug that prevents the service from starting correctly. In that situation the container will keep restarting every few seconds, which can make it harder to notice the real problem. Checking `docker-compose logs` is the first step to diagnose this.
