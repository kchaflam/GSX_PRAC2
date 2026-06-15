# Python HTTP Server Container

## Dockerfile explanation

The Dockerfile starts from `python:3.12-alpine`, a minimal Python image based on Alpine Linux. It sets `/app` as the working directory and copies only `app.py` into the container. A dedicated non-root user and group are then created, and ownership of both the `/app` directory and a `/data` directory is assigned to that user. The `/data` directory is created at build time to ensure it exists and is writable by the application. Finally, the container switches to the non-root user before running the application.

### Why `python:3.12-alpine`?

Alpine-based images are the smallest available option for Python containers. Since this application only uses the standard library and has no system-level dependencies, Alpine provides everything needed without any unnecessary packages.

| Base image           | Size   |
| -------------------- | ------ |
| `python:3.12-slim`   | 119 MB |
| `python:3.12-alpine` | 49 MB  |

Switching to the Alpine variant reduces the image size by nearly 60%. Combined with running as a non-root user, this also improves the security posture of the container.

### Dependencies

This application uses only Python's built-in `http.server` module, so there are no external packages to install. No `requirements.txt` or `pip install` steps are needed.

---

## Security & Optimizations

### Minimal base image

Switching from `python:3.12-slim` to `python:3.12-alpine` cuts the image size from 119 MB down to 49 MB. Alpine Linux is a stripped-down distribution that includes only the bare minimum to run the application. Fewer packages mean fewer potential vulnerabilities and a faster image to pull and deploy.

That said, Alpine uses `musl libc` instead of the standard `glibc`. This is not an issue for this application since it uses only the Python standard library, but it is something to keep in mind if external packages with C extensions are added later, as some may require additional build dependencies on Alpine.

### Non-root user

By default, processes inside a container run as root. If an attacker were to exploit a vulnerability in the application, running as root would give them full control over the container's filesystem. Creating a dedicated user and group and switching to them with `USER appuser` ensures the application only has access to what it actually needs. Ownership of both `/app` and `/data` is explicitly assigned to that user so the application can read its own files and write persistent logs without elevated privileges.

### Persistent data directory

The `/data` directory is created inside the container at build time and its ownership is assigned to the non-root user. This is where the application writes its log file. Creating the directory during the build and setting the correct permissions in advance avoids runtime failures when the application tries to write there as a non-root user.

### Explicit file copy

Only `app.py` is copied into the container rather than the entire project directory. This prevents any unintended files — such as local configuration, credentials, or development artifacts — from ending up inside the image.

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
Backend is running!
```

To check the persistent logs written by the application, hit the `/logs` endpoint:

```bash
curl localhost:8080/logs
```

This returns the contents of the log file stored in `/data`, showing each time the container was started.
