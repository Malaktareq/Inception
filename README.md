*This project has been created as part of the 42 curriculum by malsharq.*

# Inception (42) — Docker Infrastructure

## 📖 Description
Inception is a Docker-based system administration project where I built a small web infrastructure using Docker Compose. The stack runs inside a VM as required by 42, but it can also run directly on the host.

I built custom images for each service using dedicated Dockerfiles (NGINX, WordPress/PHP-FPM, MariaDB) and orchestrated them with a docker-compose.yml executed via a Makefile from the repository root. Images are built from minimal base distributions (Alpine/Debian) and no pre-made service images are used.
<img width="487" height="633" alt="Screenshot From 2026-01-22 13-37-20" src="https://github.com/user-attachments/assets/cc9eb111-e3fc-41e9-95d9-f09ebd4c2094" />

--------------------------------------------------------------------------------
## 🛠️ Instructions
### Prerequisites
• Tools: Docker Engine, Docker Compose, Make
.
• Permissions: Root or sudo privileges to run Docker
.
### Installation & Usage
#### 1.Clone the repo
#### 2.Set up Secrets (Mandatory)
The secrets/ directory is already present in the repository. You must manually create the password files inside it which are:
##### db_password.txt 
##### db_root_password.txt
##### wp_admin_password.txt
##### wp_user_password.txt
Note: These specific text files are configured to be ignored by Git to prevent credential leaks
,
.
#### 3.Domain Setup 
Map the project domain to your local IP address in /etc/hosts
```bash
sudo nano /etc/hosts
```

Add:
```
<VM_IP>  <login>.42.fr
```

Example:
```
127.0.1.1  malsharq.42.fr
```
#### 4.Build & run
Execute the Makefile. This will build the images, automatically create the required data volumes on the host and start the containers.
#### 🌐 Access
- Website: `https://<login>.42.fr`
- WordPress admin: `https://<login>.42.fr/wp-admin`

---
## 🏗️ Project Description & Design Choices
### The project's folder hierarchy
This project uses Docker to containerize each service (NGINX, WordPress/PHP-FPM, MariaDB) in its own isolated environment. Docker Compose coordinates the containers by creating a dedicated network for internal communication, defining persistent volumes for WordPress files and MariaDB data, and controlling startup order and restart behavior. Only NGINX is exposed to the host on port 443; WordPress and MariaDB remain accessible only inside the Docker network.

```bash
.
├── Makefile
├── secrets/
└── srcs/
├── .env
├── docker-compose.yml
└── requirements/
├── mariadb/
│   ├── Dockerfile
│   └── tools/
│   
├── nginx/
│   ├── Dockerfile
│   └── conf/
└── wordpress/
		├── Dockerfile
		└── tools/
```
### Sources included in this project
This repository includes all the files required to build and run the infrastructure from scratch (no pre-built service images are used, only base Alpine/Debian images):
- **Makefile** (root): one-command workflow to build and run the full stack.
- **srcs/docker-compose.yml**: defines the three services, the network, and the volumes.
- **srcs/.env**: contains environment variables used to configure the containers (kept out of Git for safety).
- **secrets/**: stores sensitive values as files (e.g. database passwords) so they can be mounted into containers securely (recommended over plain environment variables).
- **requirements/nginx/**:
  - **Dockerfile**
  - **conf/**: the only service where configuration files are used directly (NGINX server/TLS configuration).
- **requirements/mariadb/**:
  - **Dockerfile**
  - **tools/mariadb.sh**: initialization script that configures MariaDB on first run (database creation, users, privileges, etc.).
- **requirements/wordpress/**:
  - **Dockerfile**
  - **tools/wordpress.sh**: initialization script that installs/configures WordPress and connects it to MariaDB, then starts PHP-FPM.

In short: **NGINX is configured using config files**, while **MariaDB and WordPress are configured primarily through startup scripts** located in `tools/`.

.

---
## Design Choices
## 1) Virtual Machines vs. Docker (Why both?)

This project uses a **nested architecture**: **Docker containers running inside a Virtual Machine (VM)**.  
For the official **42 Inception** requirements, running inside a **VM is mandatory**.  
However, this repository can also run **perfectly on a host machine** (if Docker + Docker Compose are installed).

---

### ⚔️ Technical Comparison

| Feature | Virtual Machine (VM) | Docker Container |
|---|---|---|
| **Abstraction** | Hardware virtualization — emulates a full computer (CPU, RAM, disk). | OS virtualization — isolates processes in user space. |
| **Operating System** | Runs a complete guest OS (kernel + user space). | Shares the host kernel; isolates user space (filesystem, PID, etc.). |
| **Isolation** | Strong isolation (like a separate physical machine). | Lightweight isolation using **namespaces** and **cgroups**. |
| **Performance** | Heavier (more resources, slower boot). | Faster (lightweight, starts quickly). |

---

### 🏗️ Why use both? (The Inception Architecture)

Even though Docker can run directly on a host, the 42 project deliberately requires Docker inside a VM:

1. **Strict Isolation**  
   The project environment is fully separated from your physical machine. If something breaks, your host stays safe.

2. **System Administration Practice**  
   It simulates managing a remote server (the VM) instead of your local machine, forcing correct handling of permissions and configuration.

3. **The “Inception” Concept**  
   Systems within systems: containers (process-level virtualization) running inside a VM (hardware-level virtualization) on physical hardware.

---
## 2) Secrets vs. Environment Variables (Security)

Managing sensitive data is a critical part of system administration.  
This project clearly separates **general configuration** from **confidential credentials**.

---

### 🔑 Technical Comparison

| Feature | Environment Variables (`.env`) | Docker Secrets |
|---|---|---|
| **Storage location** | Plain text values loaded into the container environment. | Stored as files and mounted into the container filesystem (e.g., `/run/secrets/...`). |
| **Visibility** | Less secure — values may be exposed via container inspection tools. | More secure — provided only to permitted services as read-only files. |
| **Best use** | Non-sensitive config (domains, usernames, paths). | Sensitive data (passwords, API keys, certificates). |
| **Rotation** | Usually requires editing `.env` and restarting services. | Can be rotated by replacing secret files and restarting without rebuilding images. |

---
### 🛡️ Security Implementation Details

This project follows a strict **“No Passwords in Git”** policy to mimic real-world DevOps security practices.

#### 1) Environment Variables (`.env`)
- Used for **public configuration**, such as `DOMAIN_NAME` or `MYSQL_DATABASE`.
- Automatically loaded by Docker Compose from `srcs/.env`.
- Note: while the subject mandates a `.env` file, **storing passwords inside it is discouraged** because secrets can leak easily.

#### 2) Docker Secrets (Recommended Security Standard)
- **Rule:** any credentials/passwords committed to the repository can lead to project failure.
- **Solution:** sensitive values are injected at runtime using secrets files.
- **Mechanism:**
  1. Create secret files on the host in `secrets/` (example: `db_password.txt`).
  2. Docker mounts them into containers under `/run/secrets/` as **read-only**.
  3. Services (MariaDB / WordPress scripts) read passwords from the file path instead of environment variables.

---
## 3) Docker Network vs. Host Network (Isolation & Security)

Networking is the backbone of this infrastructure.  
To ensure service isolation and avoid exposing backend services, this project **does not allow direct host networking** for containers.

---

### 🌐 Technical Comparison

| Feature | Host Network (`network: host`) | Docker Bridge Network |
|---|---|---|
| **IP address** | Container shares the host IP address. | Container receives its own internal IP on a virtual bridge. |
| **Port exposure** | All container ports are effectively exposed on the host. | Ports are closed by default and must be explicitly published. |
| **Service discovery** | Harder to manage (localhost conflicts). | Built-in DNS: containers resolve each other by service name (e.g., `mariadb`). |
| **Subject status** | ❌ Forbidden (breaks isolation). | ✅ Mandatory (isolates services). |

---

### 🏰 The Architecture (Security Guard Model)

This project uses a **custom internal Docker network** to mimic a real-world DMZ-style setup:

1. **Forbidden methods**  
   The following are strictly banned because they weaken isolation:
   - `network: host`
   - `links:`
   - `--link`

2. **The “Security Guard” (NGINX)**  
   - NGINX is the **only** container exposed to the host.
   - It listens on **port 443 (HTTPS)** and acts as the single entry point.

3. **The protected backend**  
   - WordPress (PHP-FPM) and MariaDB run inside the isolated network:
     - WordPress/PHP-FPM (internal port typically **9000**)
     - MariaDB (internal port typically **3306**)
   - They are **not accessible directly from the host**.
   - NGINX forwards requests to WordPress, and WordPress connects to MariaDB using Docker’s internal DNS (`mariadb` service name).

---

### 🧩 Communication Flow
- **Host → NGINX** (HTTPS :443)
- **NGINX → WordPress** (internal Docker network)
- **WordPress → MariaDB** (internal Docker network via service name)
---
## 4) Docker Volumes vs Bind Mounts (Persistence)

Data persistence is required for both the database and the WordPress website files.  
To achieve this, the project uses **named Docker volumes** (as required by the subject), while also ensuring the data is stored under the required host path: `/home/<login>/data`.

---

### 📦 What is persisted?
- **MariaDB volume** → database files (tables, users, data)
- **WordPress volume** → website files (uploads, plugins, themes, wp-content)

---

### 📊 Technical Comparison

| Feature | Classic Bind Mount (service-level) | Named Volume (Docker-managed) | **Named Volume + `driver_opts` (this project)** |
|---|---|---|---|
| **Defined where** | Inside a service (`services: ... volumes:`) | Under top-level `volumes:` | Under top-level `volumes:` |
| **Host path dependency** | Strong (hard-coded host paths in service) | None (Docker chooses storage path) | Controlled (fixed path required by subject) |
| **Portability** | Lower (depends on host FS structure) | Higher | Medium (path fixed by requirement) |
| **Management** | Manual (host dir ownership/cleanup) | Easy (`docker volume ls/rm/inspect`) | Easy (`docker volume ...`) |
| **Subject intent** | Often discouraged for required storages | ✅ Required concept | ✅ Best match for “named volumes + required path” |

---

### ✅ How persistence is implemented (what we do)
Instead of using direct service bind mounts, we define **named volumes** and configure them with `driver_opts` so Docker stores their data under the subject-required directory:

- `/home/<login>/data/db`
- `/home/<login>/data/wp`

This keeps the abstraction of **named volumes**, but guarantees the host storage location matches the 42 requirement (`/home/<login>/data`).

---

### 🔍 Difference from classic bind mounts
- **Classic bind mount (not used here):** mounts a host folder directly in a service definition (high host dependency).
- **Our approach:** uses **named volumes**, but binds the backing storage directory to a fixed host path using `driver_opts`.

---

--------------------------------------------------------------------------------
## 🤖 AI Usage

Per the subject instructions, the use of AI is documented below.

### ✅ What AI was used for
AI tools were used to support learning, reduce repetitive work, and troubleshoot issues during development, including:
- Generating/validating **regex** patterns for NGINX configuration needs.
- Clarifying Dockerfile behavior such as **`ENTRYPOINT` vs `CMD`** and best practices around PID 1.
- Troubleshooting **permissions and ownership issues** (especially with volumes and MariaDB initialization).
- Debugging container startup problems (compose networking, service dependencies, environment/secrets reading).
- Explaining concepts to ensure the project decisions were understood (networks, volumes, secrets, TLS basics).

### 🧰 Tools used
- **ChatGPT**
- **Gemini**

### 🧠 Prompting & verification strategy
- AI was used mainly for **concept explanations** and **targeted debugging** rather than copying full solutions.
- Any suggested configuration/code was **reviewed, edited, and tested** inside the VM environment.
- Only changes that were fully understood and reproducible were kept in the final repository.
---
## 📚 Resources
### Containers & Docker basics
- The Enterprisers Project — *How to explain containers in plain English*  
  https://enterprisersproject.com/article/2018/8/how-explain-containers-plain-english
- Ankit Sahay (Medium) — *What is Docker and what problem does it solve?*  
  https://ankitsahay.medium.com/what-is-docker-and-what-problem-does-it-solve-a019b73ff8aa
- YouTube playlist video  
  https://www.youtube.com/watch?v=0qotVMX-J5s&list=PLcgYNRANzNIay10MEtd77PXAkHZYs89VK&index=2

### Images / registries / hub
- Red Hat — *What is a container registry?*  
  https://www.redhat.com/en/topics/cloud-native-apps/what-is-a-container-registry
- Docker Hub  
  https://hub.docker.com/

### Cheat sheets & practical docs
- DevOpsCycle — *The Ultimate Docker Cheat Sheet (PDF)*  
  https://devopscycle.com/pdfs/the-ultimate-docker-cheat-sheet.pdf
- Docker Docs — Compose file reference (`init`)  
  https://docs.docker.com/reference/compose-file/#init

### Secrets & security
- Semaphore — *Docker secrets management*  
  https://semaphore.io/blog/docker-secrets-management

### Database concepts (MariaDB)
- MariaDB Docs — *ACID & concurrency control with transactions*  
  https://mariadb.com/docs/general-resources/database-theory/acid-concurrency-control-with-transactions

### TLS / OpenSSL
- Baeldung — *OpenSSL Self-Signed Certificate*  
  https://www.baeldung.com/openssl-self-signed-cert
- F5 Glossary — *OpenSSL*  
  https://www.f5.com/glossary/openssl
- YouTube video (OpenSSL / certificates)  
  https://www.youtube.com/watch?v=T4Df5_cojAs

### NGINX & WordPress tooling
- NGINX docs — `location` directive (core module)  
  https://nginx.org/en/docs/http/ngx_http_core_module.html#location
- WordPress Developer Docs — WP-CLI commands  
  https://developer.wordpress.org/cli/commands/


