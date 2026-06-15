# Nginx Container

## Dockerfile explanation

The Dockerfile starts from `nginx:alpine`, a minimal Nginx image based on Alpine Linux. Only the `index.html` file is copied into the Nginx web root, keeping the container contents as small and explicit as possible.

### Why `nginx:alpine`?

Alpine-based images are significantly smaller than their standard counterparts while still providing full functionality. For a container that only serves static files, there is no reason to carry the extra weight of a larger base image.

| Base image     | Size   |
| -------------- | ------ |
| `nginx:latest` | 161 MB |
| `nginx:alpine` | 62 MB  |

Switching to the Alpine variant reduces the image size by over 60%, which means faster pulls, less storage usage, and a smaller attack surface.

### Dependencies

This application has no external dependencies beyond Nginx itself, which is already included in the base image. It only serves static files, so no additional packages or libraries are needed.

---

## Security & Optimizations

### Minimal base image

Using `nginx:alpine` instead of `nginx:latest` is both a size and a security improvement. A smaller image contains fewer packages, which directly reduces the number of potential vulnerabilities. A full Debian-based image ships with many tools and libraries that are never used in a container serving static files — each of those is an unnecessary risk.

### Multistage build decision

A multistage build is useful when an image needs a build phase, for example compiling assets or installing build-only dependencies. This Nginx image only serves a static `index.html` file, so there is no separate build artifact to copy into a runtime image. Adding a multistage build here would make the Dockerfile more complex without reducing the final image.

### Layer ordering

The Dockerfile keeps the layer order simple and stable: start from the base image, then copy the static file. Since there are no package installation steps, dependency layers do not need to be rebuilt. If more static files or generated assets are added later, build-heavy steps should come before frequently changing content so Docker can reuse cached layers.

### Copy only what is needed

The Dockerfile copies only `index.html` rather than the entire project directory. Avoiding a broad `COPY . .` means build artifacts, configuration files, or any sensitive files that happen to be in the project folder will never end up inside the image unintentionally.

---

## Prerequisites

Docker must be installed and the Docker daemon must be running before executing any of the commands below. If you are not sure whether Docker is set up correctly on your machine, refer to the [Troubleshooting guide](DockerTroubleshooting.md) for installation and service check instructions.

---

## Build

From the directory containing your Dockerfile, build the image and tag it as `nginx-gsx`:

```bash
docker build -t nginx-gsx .
```

## Run

Start a container from the image, mapping port 80 on your machine to port 80 inside the container:

```bash
docker run -p 80:80 nginx-gsx
```

## Test

Send a request to the server to confirm it is responding correctly:

```bash
curl localhost
```

You should receive the HTML content of your site. You can also open `http://localhost` directly in your browser.
