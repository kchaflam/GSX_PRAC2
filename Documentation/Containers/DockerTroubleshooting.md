# Docker Troubleshooting

## Port already in use

If the port you are trying to map is already occupied on your machine, Docker will refuse to start the container. Use a different host port by changing the left side of the `-p` flag:

```bash
docker run -p 8081:80 nginx-gsx
docker run -p 9090:8080 python-app
```

---

## Container exits immediately

If the container stops right after starting, check the logs to see what went wrong:

```bash
docker logs <container_id>
```

To get the container ID, list all containers including stopped ones:

```bash
docker ps -a
```

---

## Cannot connect to the server

If `curl` or the browser gets no response, first confirm the container is actually running:

```bash
docker ps
```

If it does not appear in the list, it has stopped. Check the logs as shown above. Also make sure you are using the correct port on the host side.

---

## Image not found when running

If Docker says it cannot find the image, it has either not been built yet or was built with a different tag. List all locally available images to check:

```bash
docker images
```

If the image is missing, go back and run the build command from the correct directory.

---

## Build fails with "no such file or directory"

This usually means Docker cannot find a file it is trying to copy, such as `app.py` or the static web files. Make sure you are running the build command from the directory that contains both the Dockerfile and all the required files.

---

## Changes not reflected after rebuild

Docker caches layers to speed up builds. If your changes are not showing up, force a clean rebuild with the `--no-cache` flag:

```bash
docker build --no-cache -t nginx-gsx .
docker build --no-cache -t python-app .
```

---

## Stopping a running container

To stop a container gracefully, use its ID or name:

```bash
docker stop <container_id>
```

To stop all running containers at once:

```bash
docker stop $(docker ps -q)
```

---

## Docker is not installed or not running

Before building or running any container, Docker must be installed and the Docker daemon must be active. If any command returns `docker: command not found` or `Cannot connect to the Docker daemon`, follow the steps below.

### Install Docker

Install Docker Engine using the official convenience script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

Verify the installation was successful:

```bash
docker --version
```

### Check and start the Docker service

Check whether the Docker daemon is currently running:

```bash
sudo systemctl status docker
```

If it is not running, start it:

```bash
sudo systemctl start docker
```

To make Docker start automatically on every boot:

```bash
sudo systemctl enable docker
```

### Run Docker without sudo

By default, Docker requires root privileges. To run commands as a regular user, add your user to the `docker` group:

```bash
sudo usermod -aG docker $USER
```

Then apply the group change to your current session without logging out:

```bash
newgrp docker
```

Confirm everything is working correctly:

```bash
docker info
```