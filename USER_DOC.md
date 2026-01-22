# USER_DOC.md — User / Administrator Guide

This document explains how to use the **Inception** stack as an end user or administrator: what services it provides, how to start/stop it, how to access WordPress, where credentials live, and how to verify everything is running correctly.

> **Note (42 requirement):** For the official 42 Inception project, the stack must run inside a **Virtual Machine**.  
> This repository can also run on a **host machine** as long as Docker + Docker Compose are installed.

---

## 1) What services are provided?

This stack provides a small web infrastructure composed of **three containers**:

1. **NGINX (HTTPS entrypoint)**
   - The only public entrypoint to the stack.
   - Listens on **port 443** using **TLS v1.2 / v1.3**.
   - Proxies requests to WordPress (PHP-FPM) over the internal Docker network.

2. **WordPress + PHP-FPM (application)**
   - Runs WordPress with PHP-FPM (no nginx inside).
   - Receives requests only from NGINX through the internal Docker network.
   - Stores website files in a persistent volume.

3. **MariaDB (database)**
   - Stores WordPress data (users, posts, settings, etc.).
   - Reachable only from WordPress through the internal Docker network.
   - Stores database files in a persistent volume.

---

## 2) How to start the project

### Prerequisites
- Docker Engine installed
- Docker Compose installed
- `make` installed

### Required domain (recommended for 42)
Map your domain to your VM/host IP in `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add:
```
<YOUR_IP>  <login>.42.fr
```

Example:
```
127.0.0.1  malsharq.42.fr
```

### Configuration & credentials
- General configuration lives in: `srcs/.env`
- Sensitive credentials are stored as files in: `secrets/` and mounted into containers under `/run/secrets/`

---

## 3) Start / stop commands

### Start (build + run)
From the repository root:

```bash
make
```


### Stop
```bash
make down
```

### Full cleanup (containers/images/volumes depending )
```bash
make remove
```

### Manual alternative (without Makefile)
You can also run docker compose directly:

```bash
cd srcs
docker compose up -d --build
```

Stop it with:
```bash
cd srcs
docker compose down
```

---

## 4) Access the website & admin panel

### Website
Open in a browser:
- `https://<login>.42.fr`

### WordPress admin panel
- `https://<login>.42.fr/wp-admin`

> If you use a self-signed certificate, your browser may show a warning. This is expected for local VM testing.

Quick CLI test:
```bash
curl -kI https://<login>.42.fr
```

---

## 5) Locate and manage credentials

### `.env` (configuration only)
File:
- `srcs/.env`

Typical non-sensitive variables include:
- `DOMAIN_NAME`
- `MYSQL_DATABASE`
- `MYSQL_USER` (username is usually fine to keep here)

> **Good practice:** avoid storing passwords in `.env` when secrets are available.

### `secrets/` (sensitive values)
Folder:
- `secrets/`

This project uses secret files for sensitive values :
- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt` 

Inside the containers, secrets are typically available at:
- `/run/secrets/<secret_name>`

### How to rotate a password
1. Update the secret file in `secrets/` (on the VM/host).
2. Restart the affected service(s):

```bash
cd srcs
docker compose restart mariadb wordpress
```
---

## 6) Check that services are running correctly

### A) Check container status
```bash
cd srcs
docker compose ps
```
You should see **nginx**, **wordpress**, **mariadb** in a running state.

### B) Check logs
```bash
cd srcs
docker compose logs -f
```

Or per service:
```bash
cd srcs
docker compose logs -f nginx
docker compose logs -f wordpress
docker compose logs -f mariadb
```

### C) Verify HTTPS Connection

```bash
curl -kI https://<login>.42.fr
```


### D) Check internal connectivity (network)
Enter the WordPress container and ping MariaDB by service name:
```bash
cd srcs
docker compose exec wordpress ping -c 1 mariadb
```

### E) Confirm WordPress can reach the database
If your wordpress container has a client installed, you can test MariaDB connectivity (depends on your image):
```bash
cd srcs
docker compose exec wordpress sh -lc "mariadb-admin ping -h localhost -u $DB_USER -p$(cat /run/secrets/db_password)" -e "SELECT 1;"'

```
---

## 7) Common admin operations

### Restart a single service
```bash
cd srcs
docker compose restart nginx
```

### Rebuild images after changes
```bash
cd srcs
docker compose up -d --build
```

### Check volumes (persistence)
```bash
docker volume ls
docker volume inspect <volume_name>
```

Your persistent data should remain under:
- `/home/<login>/data/wp`
- `/home/<login>/data/db`

---

## 8) Troubleshooting quick tips

- **Site not reachable**
  - Check `docker compose ps`
  - Check NGINX logs: `docker compose logs -f nginx`
  - Verify `/etc/hosts` points `<login>.42.fr` to the correct IP

- **WordPress shows DB connection error**
  - Check MariaDB logs: `docker compose logs -f mariadb`
  - Check WordPress logs: `docker compose logs -f wordpress`
  - Confirm secrets are mounted under `/run/secrets/`
  - Confirm WordPress can resolve `mariadb` via Docker DNS

- **Data reset after rebuild**
  - Ensure you are using named volumes correctly and that `/home/<login>/data/*` exists and is writable.
