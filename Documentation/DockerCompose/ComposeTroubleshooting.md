# Docker Compose — Troubleshooting

## Docker Compose is not installed

Docker Compose is a separate tool from Docker Engine and may not be installed even if Docker itself is working. If `docker-compose` returns `command not found`, install it with the following commands:

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

Verify the installation was successful:

```bash
docker-compose --version
```

If Docker itself is not installed or the daemon is not running, refer to the [Docker Troubleshooting guide](../Containers/DockerTroubleshooting.md) first.

---

## A service fails to start

A service can fail to start for many reasons: a misconfigured environment variable, a port conflict, or an error in the application code. Check the logs of the affected service to identify the cause:

```bash
docker-compose logs nginx
docker-compose logs backend
```

If the container started and then immediately stopped, you can also inspect stopped containers to get more context:

```bash
docker ps -a
```

---

## Nginx starts before the backend is ready

The `depends_on` directive with a health check ensures Nginx waits for the backend to be healthy before starting. If Nginx still seems to start too early, check whether the backend health check is actually passing:

```bash
docker-compose ps
```

The backend should show as `healthy` before Nginx comes up. If it stays in `starting` for a long time, the health check is likely failing — check the backend logs for errors.

---

## Port already in use

If a port is already occupied on your machine, Compose will fail to bind it and the affected service will not start. Change the host-side port in your `.env` file to a free port:

```
NGINX_PORT=8081
BACKEND_PORT=9090
```

Then restart the stack for the change to take effect:

```bash
docker-compose down
docker-compose up --build -d
```

---

## Environment variables not being picked up

If the stack starts with unexpected values or missing configuration, make sure the `.env` file is in the same directory as `docker-compose.yml` and that the variable names match exactly what is referenced in the Compose file. To confirm what values Compose is actually resolving before starting the stack:

```bash
docker-compose config
```

This prints the fully resolved `docker-compose.yml` with all variables substituted, making it easy to spot mismatches or missing values.

---

## Changes to the Dockerfile not reflected

Compose caches built images to speed up subsequent starts. If changes to a Dockerfile or application file are not showing up in the running container, force a clean rebuild and recreate all containers:

```bash
docker-compose up --build --force-recreate
```

---

## Volume data not persisting

If data written by the backend is disappearing between restarts, the most likely cause is that the stack was stopped with `docker-compose down -v`, which removes volumes along with the containers. Use `docker-compose down` without the `-v` flag to preserve the volume data.

To confirm whether the volume still exists:

```bash
docker volume ls
```

---

## Services cannot reach each other

Services communicate using their service name as the hostname inside the Compose network. If a service cannot reach another, first confirm the target service is running and healthy with `docker-compose ps`. Then verify that the hostname being used matches exactly the service name defined in `docker-compose.yml`. You can test connectivity directly by opening a shell inside a container and sending a request manually:

```bash
docker-compose exec nginx sh
wget -qO- http://backend:8080
```

If this fails, the container may not be on the same network or the target service may not be running.
