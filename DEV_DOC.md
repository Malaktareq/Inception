# Developer Documentation (DEV_DOC.md)

This document shows how to set up the environment from scratch, build and launch the project using the provided `Makefile` and Docker Compose, manage containers and volumes, and where project data is stored and persisted.

## Prerequisites

- Linux (or WSL2 on Windows / macOS with Docker Desktop)
- Docker Engine and Docker Compose (v2 recommended)
- GNU Make
- git

Install example (Debian/Ubuntu):

```bash
sudo apt update
sudo apt install -y git make curl
# Install Docker (official convenience script)
curl -fsSL https://get.docker.com | sh
# Add current user to docker group (re-login required)
sudo usermod -aG docker $USER
# Install docker-compose plugin if needed
sudo apt install -y docker-compose-plugin
```

## Repository layout (relevant files)

- Makefile
- docker-compose.yml (under `srcs/`)
- secrets/ (contains DB and WP credentials - not committed to public repos)
- srcs/ (Dockerfiles and service configs)
  - srcs/nginx/conf/default.conf
  - srcs/mariadb/Dockerfile and tools/
  - srcs/wordpress/Dockerfile and tools/

## Configuration & Secrets

- Secrets are stored in the `secrets/` folder at the repo root. Expected files:
  - `secrets/db_root_password.txt`
  - `secrets/db_password.txt`
  - `secrets/wp_admin_password.txt`
  - `secrets/wp_user_password.txt`

Ensure these files exist and contain the passwords before launching the stack. Example:

```bash
echo "my_root_pw" > secrets/db_root_password.txt
echo "my_db_pw" > secrets/db_password.txt
echo "admin_pw" > secrets/wp_admin_password.txt
echo "user_pw" > secrets/wp_user_password.txt
```

If you prefer environment variables, update the `docker-compose.yml` and `srcs/*/tools` scripts accordingly.

## Build and Launch (Makefile + Docker Compose)

From the repository root :

- Build images and run containers:

```bash
make run
```

- Or build using Docker Compose in `srcs/` (if `docker-compose.yml` is located there):

```bash
cd srcs
docker compose build
```


- Launch the full stack (foreground):

```bash
cd srcs
docker compose up
```

- Launch as detached/background services:
```bash
make 
```
or
```bash
cd srcs
docker compose up -d
```

- Stop the stack:
```bash
make down
```
or
```bash
cd srcs
docker compose down
```

- Stop and remove containers, networks,images, and named volumes created by the compose file:
```bash
make remove
```
or
```bash
cd srcs
docker compose down -v
docker rmi -f `docker images -q`
```

## Managing Containers and Volumes

Common docker commands you may need:

- List containers:

```bash
docker ps -a
```

- View container logs (replace `<container>` with name/id):

```bash
docker logs -f <container>
```

- Exec into a running container (example for a shell):

```bash
docker exec -it <container> bash
```

- Remove stopped containers and dangling images:

```bash
docker system prune --volumes
```

- List named volumes:

```bash
docker volume ls
```

- Inspect a volume (to find mountpoint on host):

```bash
docker volume inspect <volume_name>
```

- Remove a named volume:

```bash
docker volume rm <volume_name>
```

If a `Makefile` defines helper targets (e.g., `make clean`, `make down`), use those to ensure consistent teardown.

## Data storage & persistence

This project persists service data using Docker volumes (defined in `srcs/docker-compose.yml`). Typical locations:

- MariaDB data: persisted to a Docker named volume (e.g., `mariadb_data`) mapped to the database container's data directory (often `/var/lib/mysql`).
- WordPress uploads and state: persisted to a named volume or a bind mount (check `docker-compose.yml`, often mapped to `/var/www/html` for WordPress files).
- Nginx config: typically read from `srcs/nginx/conf/default.conf` and not part of a volume unless explicitly mounted.

To identify where data is stored on the host, inspect the compose file for `volumes:` and then inspect the named volume:


## Useful developer tips

- Inspect the `Makefile` for shorthand commands (e.g., `make up`, `make build`, `make down`).
- Keep secrets out of version control; use `secrets/` or environment variable injection.
- If ports conflict on your host, adjust the `ports:` mapping in `srcs/docker-compose.yml`.
- When iterating on service code (e.g., WordPress PHP files), use bind mounts for the site code to avoid rebuilding images every change.

## Troubleshooting

- If containers fail on startup, check logs:

```bash
cd srcs
docker compose logs <container-name>
```

- If MariaDB initialization fails, ensure the `secrets/*.txt` passwords are correctly set and accessible to the compose process.

- Permissions issues with bind mounts: ensure the container user has appropriate permissions on the host path or use Docker named volumes.

## Where to look in this repo

- Makefile: [Makefile](Makefile)
- Docker Compose file: [srcs/docker-compose.yml](srcs/docker-compose.yml)
- Nginx config: [srcs/nginx/conf/default.conf](srcs/nginx/conf/default.conf)
- Dockerfiles and service tools: [srcs/](srcs/)
- Secrets folder: [secrets](secrets/)

