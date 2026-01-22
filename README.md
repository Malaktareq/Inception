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

--------------------------------------------------------------------------------
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
### 
Below is a comparison of the key technical concepts implemented in this infrastructure:
1. Virtual Machines vs. Docker
• Virtual Machines (VMs): Emulate entire hardware systems. Each VM runs a full Operating System (kernel + user space), making them heavy and resource-intensive.
• Docker (Containers): Virtualize the OS kernel. Containers are lightweight processes that share the host's kernel but maintain isolated user spaces (filesystems, PID namespaces).
• Choice: We run Docker inside a VM to practice strict system administration and isolation, ensuring the host machine remains unaffected by the project environment
,
.
2. Secrets vs. Environment Variables
• Environment Variables: Stored in .env files and passed to containers. While convenient, they can be insecure if inspecting the container via docker inspect reveals values in plain text.
• Docker Secrets: Encrypted at rest and mounted as files inside the container (usually in /run/secrets/). They are only accessible to services explicitly granted access.
• Choice: While .env files are mandatory for configuration variables
, this project strongly recommends/implements secrets for sensitive credentials (like DB passwords) to adhere to DevOps security best practices,
.
3. Docker Network vs. Host Network
• Host Network: The container shares the host's networking namespace. Use of network: host is strictly forbidden in this project
.
• Docker Network: Creates a virtual bridge network. Containers can communicate securely via service names (DNS resolution) without exposing internal ports (like 3306 or 9000) to the outside world.
• Choice: A custom bridge network is established. Only NGINX exposes port 443 to the host; all other traffic (WordPress <-> MariaDB) remains internal to the docker network
.
4. Docker Volumes vs. Bind Mounts
• Bind Mounts: Map a specific file/directory on the host directly to the container. They depend heavily on the host's filesystem structure and permissions.
• Docker Volumes: Managed completely by Docker (usually stored in /var/lib/docker/volumes). They are safer, portable, and easier to back up.
• Choice: We use Named Volumes with a custom driver option to store data in /home/<login>/data. This satisfies the requirement for persistence on the host while utilizing Docker's volume management commands rather than crude bind mounts
,
.

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
