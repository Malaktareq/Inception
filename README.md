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

### 🔒 Security Workflow

```mermaid
graph LR
    User[👤 You (Administrator)] -->|Creates| SecretFiles[📄 secrets/*.txt]

    subgraph Host_VM [Host VM]
        SecretFiles
        EnvFile[📄 .env (Config Only)]
    end

    subgraph Container [🐳 Container]
        MountPoint[📂 /run/secrets/db_pass]
        App[⚙️ Application]
    end

    SecretFiles -.->|Mounted as Read-Only| MountPoint
    EnvFile -.->|Loaded as Env Vars| App
    MountPoint -->|Reads Password| App
```
--------------------------------------------------------------------------------
📚 Resources & AI Usage
References
• Docker Documentation
• NGINX Documentation
• MariaDB - Installing and Using
• Docker Networking Guide
AI Usage
Per the subject instructions, the use of AI is documented below:
• Tasks:
    ◦ Example: Generating regex for NGINX configuration files.
    ◦ Example: Clarifying the difference between ENTRYPOINT and CMD in Dockerfiles.
    ◦ Example: Troubleshooting permissions issues with the MariaDB startup script.
• Tools Used: ChatGPT / Copilot / DeepSeek.
• Prompting Strategy: AI was used to explain concepts (like PID 1 management) and debug specific errors. All code generated was reviewed and tested to ensure understanding of the underlying logic
,.
