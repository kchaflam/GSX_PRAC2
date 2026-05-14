# Python HTTP Server Container — Documentation

## Dockerfile explanation

The Dockerfile starts from `python:3.12-alpine`, a minimal Python image based on Alpine Linux. It sets a `PORT` environment variable and `/app` as the working directory. Only `app.py` is copied into the container. For security, a dedicated non-root user and group are created and assigned ownership of the working directory, and the container runs as that user. The `EXPOSE 8080` instruction documents the port the application listens on.

### Why `python:3.12-alpine`?

Alpine-based images are the smallest available option for Python containers. Since this application only uses the standard library and has no system-level dependencies, Alpine provides everything needed without any unnecessary packages.

| Base image | Size |
|------------|------|
| `python:3.12-slim` | 119 MB |
| `python:3.12-alpine` | 49 MB |

Switching to the Alpine variant reduces the image size by nearly 60%. Combined with running as a non-root user, this also improves the security posture of the container.

### Dependencies

This application uses only Python's built-in `http.server` module, so there are no external packages to install. No `requirements.txt` or `pip install` steps are needed.

---

## Security & Optimizations

### Minimal base image

Switching from `python:3.12-slim` to `python:3.12-alpine` cuts the image size from 119 MB down to 49 MB. Alpine Linux is a stripped-down distribution that includes only the bare minimum to run the application. Fewer packages mean fewer potential vulnerabilities and a faster image to pull and deploy.

That said, Alpine uses `musl libc` instead of the standard `glibc`. This is not an issue for this application since it uses only the Python standard library, but it is something to keep in mind if external packages with C extensions are added later, as some may require additional build dependencies on Alpine.

### Non-root user

By default, processes inside a container run as root. If an attacker were to exploit a vulnerability in the application, running as root would give them full control over the container's filesystem. Creating a dedicated user and group and switching to them with `USER appuser` ensures the application only has access to what it actually needs. Ownership of the `/app` directory is explicitly assigned to that user so the application can still read its own files.

### Explicit file copy

Only `app.py` is copied into the container rather than the entire project directory. This prevents any unintended files — such as local configuration, credentials, or development artifacts — from ending up inside the image.

### Environment variable for port

The port is defined as an environment variable (`ENV PORT=8080`) rather than being hardcoded throughout the application. This makes it straightforward to change the port at build time or override it at runtime without modifying the source code.

---

## Prerequisites

Docker must be installed and the Docker daemon must be running before executing any of the commands below. If you are not sure whether Docker is set up correctly on your machine, refer to the [Troubleshooting guide](DockerTroubleshooting.md) for installation and service check instructions.

---

## Build

From the directory containing your Dockerfile and `app.py`, build the image and tag it as `python-app`:

```bash
docker build -t python-app .
```

## Run

Start a container from the image, mapping port 8080 on your machine to port 8080 inside the container:

```bash
docker run -p 8080:8080 python-app
```

## Test

Send a request to the server to confirm it is responding correctly:

```bash
curl localhost:8080
```

The server should reply with:

```
The app container is working fine!
```