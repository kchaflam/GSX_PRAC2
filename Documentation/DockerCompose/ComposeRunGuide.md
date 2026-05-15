# Docker Compose — Build, Run & Test

## Prerequisites

Docker and Docker Compose must be installed and the Docker daemon must be running. A `.env` file must exist in the same directory as `docker-compose.yml` with the required variables populated. If you are not sure whether your setup is correct, refer to the [Troubleshooting guide](docker-compose-troubleshooting.md).

---

## Build & Start

From the directory containing `docker-compose.yml`, build all images from their Dockerfiles and start the services. The `--build` flag ensures the images are rebuilt every time, so any changes to the Dockerfiles or application code are always reflected:

```bash
docker-compose up --build
```

Running without `-d` keeps the logs printed to the terminal, which is useful during development to catch errors immediately. To run the stack in the background instead and free up the terminal:

```bash
docker-compose up --build -d
```

Due to the `depends_on` health check configuration, Nginx will only start once the backend has passed its first health check. This means the stack may take a few seconds to be fully ready after the command returns.

---

## Test

Once the stack is up, verify that all services are running and check their health status:

```bash
docker-compose ps
```

Both services should appear as `running` and eventually transition to `healthy`. If a service shows as `starting`, wait a few seconds and run the command again.

Verify the Nginx service is serving content correctly:

```bash
curl localhost:80
```

Verify the backend service is responding to requests:

```bash
curl localhost:8080
```

Check that the backend is writing and reading persistent logs correctly:

```bash
curl localhost:8080/logs
```

This endpoint reads from the `/data` volume, so a successful response confirms both that the application logic is working and that the volume is mounted and accessible.

### Service-to-service communication

To verify that services can reach each other within the Compose network, open a shell inside the Nginx container and send a request directly to the backend using its service name:

```bash
docker-compose exec nginx sh
wget -qO- http://backend:8080
```

A successful response confirms that internal DNS resolution is working and that the two containers are on the same network.

---

## Logs

To follow the live output of all services at once, useful for monitoring the stack or catching errors in real time:

```bash
docker-compose logs -f
```

To check the logs of a specific service only:

```bash
docker-compose logs backend
docker-compose logs nginx
```

---

## Stop

To stop all containers and remove them while keeping the persistent volume intact, so data is not lost:

```bash
docker-compose down
```

To stop the stack and also delete the persistent volume. Only do this if you intentionally want to wipe all stored data:

```bash
docker-compose down -v
```
