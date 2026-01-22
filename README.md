*This project has been created as part of the 42 curriculum by malsharq.*

# Inception (42) — Docker Infrastructure inside a VM

## 📖 Description
Inception is a System Administration exercise that aims to broaden knowledge of system administration by using **Docker**. The project must be done inside a **Virtual Machine**, where you virtualize several Docker images and build a small web infrastructure using **docker compose**. :contentReference[oaicite:0]{index=0}

You must create your own images (one Dockerfile per service) and orchestrate them with a `docker-compose.yml` called by a **Makefile at the repository root**. Pulling ready-made images from DockerHub is forbidden (except the base Alpine/Debian). :contentReference[oaicite:1]{index=1}

--------------------------------------------------------------------------------
🛠️ Instructions
Prerequisites
• This project is designed to run inside a Virtual Machine
.
• Docker Engine and Docker Compose must be installed
.
• make utility.
Installation & Configuration
1. Clone the repository:
2. Environment Setup: Create a .env file in srcs/ based on the template. Do not commit your actual passwords to Git
.
3. Host Data Volumes: The project requires persistent data stored on the host VM at a specific location. Ensure these directories exist (or the Makefile should create them):
4. (Note: Replace <YOUR_USER> with your VM username as per the subject requirements
.)
5. Domain Setup: Map the domain to your local IP in /etc/hosts:
Execution
• Build and Start: Run the following command from the root directory:
• This command uses docker-compose.yml located in srcs/ to build images and start the containers
.
• Stop services:
• View Logs:

--------------------------------------------------------------------------------
🏗️ Project Description & Design Choices
This project utilizes Docker to containerize services, ensuring consistency across environments. The source code is organized into a srcs folder containing the docker-compose.yml and a requirements folder with dedicated directories (Dockerfile + config) for each service (MariaDB, NGINX, WordPress)
.
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
