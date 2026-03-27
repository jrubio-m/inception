# DEV_DOC.md

##  Step 1: Environment Setup

This section explains how to set up the project from scratch, starting from a clean system.

The project is developed and tested inside a virtual machine to ensure isolation and reproducibility.

---

* ### _Virtual Machine Setup_

The first step is to create a virtual machine where the entire project will run.

A minimal installation of Lubuntu is used to reduce resource consumption and keep the environment clean.

Steps:

- Download Lubuntu Minimal ISO from the official website
- Create a new virtual machine using VirtualBox (or similar)
- Allocate resources:
  - RAM: at least 2GB (recommended 4GB)
  - CPU: 2 cores
  - Disk: at least 20GB (dynamic allocation is fine)
- Mount the Lubuntu ISO as boot device
- Start the VM and follow the installation process
- Select minimal installation when prompted

After installation:

- Update the system:
```bash
sudo apt update && sudo apt upgrade -y
```
---

* ### _Base System Preparation_

After installing the operating system, the system must be prepared with essential development tools and utilities required for building and managing the project.

Install the following packages:
```bash
sudo apt install -y \
    build-essential \
    curl \
    wget \
    git \
    vim \
    ca-certificates \
    gnupg \
    lsb-release
```
These packages are required for:

- `build-essential`: compiling software if needed
- `curl` / `wget`: downloading external resources
- `git`: version control
- `vim`: file editing inside the VM
- `ca-certificates` and `gnupg`: required for secure package installation (important for Docker)
- `lsb-release`: helps identify the system version for repository setup

Keeping the system minimal avoids unnecessary overhead and improves performance inside the virtual machine.

---

* ### _SSH Installation (Optional)_

Install ssh:
```bash
sudo apt update 
sudo apt install -y ssh
```

Start and enable ssh service:
```bash
systemctl start ssh
systemctl enable ssh
```

Allow ssh in ufw:
```bash
sudo ufw allow
```

---

* ### _Docker Installation_

Docker must be installed using the official Docker repository to ensure up-to-date and secure packages.

Add Docker’s official GPG key:
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

Set up the Docker repository:
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Update package index:
```bash
sudo apt update
```

Install Docker and related tools:
```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

* ### _Docker Service Configuration_

Start Docker service immediately and enable Docker to start automatically on system boot

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

---

* ### _Docker Permissions Setup_

By default, Docker requires root privileges to run commands.

To avoid using `sudo` every time, add your user to the `docker` group:
```bash
sudo usermod -aG docker $USER
```

After this, you must log out and log back in (or reboot) for the changes to take effect.

To verify that Docker works without sudo:
```bash
docker run hello-world
```

A full logout/login is required for this change to take effect.

---
### `⚠️ Security Note: `

_Adding a user to the docker group effectively grants root-level privileges._

_This is because Docker can control the host system through containers._

_This setup is acceptable in a local development environment (such as this project), but should be carefully considered in production systems._

---
---
---

## Step 2: Project Structure Initialization

The project must follow a strict structure.

Create the base directories:
```bash
mkdir -p ~/inception/srcs/requirements
mkdir -p ~/inception/secrets
```

Navigate into the project directory:
```bash
cd ~/inception
```

---
---
---

## Step 3: Docker Compose Setup

Docker Compose is required to define and manage multi-container applications.

It is installed together with Docker as a plugin.

To verify that Docker Compose is available:
```bash
docker compose version
```

---

* ### _Docker Compose Overview_

The project uses Docker Compose to orchestrate multiple services that work together as a small infrastructure.

The architecture is composed of three main services:

- NGINX: acts as the only entry point, handling HTTPS (TLS)
- WordPress: runs with php-fpm to process dynamic content
- MariaDB: stores the WordPress database

The services communicate through a dedicated Docker network.

Two named volumes are used for data persistence:

- WordPress database
- WordPress website files

All services are isolated in separate containers, following the requirement of one service per container.

---

* ### _Docker Compose File_

The `docker-compose.yml` file defines the full infrastructure of the project.

Final structure:

```yaml
version: "3.8"

services:

  nginx:
    build: ./requirements/nginx
    container_name: nginx
    ports:
      - "443:443"
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception
    depends_on:
      - wordpress
    restart: always

  wordpress:
    build: ./requirements/wordpress
    container_name: wordpress
    env_file:
      - .env
    secrets:
      - db_password
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - inception
    depends_on:
      - mariadb
    restart: always

  mariadb:
    build: ./requirements/mariadb
    container_name: mariadb
    env_file:
      - .env
    secrets:
      - db_password
      - db_root_password
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - inception
    restart: always

networks:
  inception:
    driver: bridge

volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/wordpress

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/<login>/data/mariadb

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
```

---

* ### _Explanation_

```yaml
version: "3.8"
```

This line indicates the Compose file format version.

It defines which syntax is expected in the file and helps keep the configuration explicit and consistent.

Even if modern Docker Compose versions are more flexible about this field, it is still commonly included for clarity.

```yaml
services:
```

This section contains all the containers that make up the infrastructure.

Each service represents one role in the project and follows the rule that each service must run inside its own dedicated container.

In this project, the services are:

- nginx

- wordpress

- mariadb

```yaml
  nginx:
```

This is the service responsible for receiving external HTTPS traffic.

It is the only public entry point of the infrastructure, as required by the subject.

NGINX does not contain WordPress logic or database logic. Its role is only to handle secure web traffic and forward requests to WordPress through the internal Docker network.

```yaml
  wordpress:
```

This service runs WordPress with PHP-FPM.

It is responsible for executing the PHP application and serving the website content internally.

It is not directly exposed to the host machine. It only communicates with NGINX and MariaDB inside the Docker network.

```yaml
  mariadb:
```

This service provides the database used by WordPress.

It stores all persistent application data such as users, posts, configuration, and metadata.

It is not exposed to the outside and only accepts internal connections from the WordPress service.

```yaml
    build:
```

The build field tells Docker Compose to build an image from a local Dockerfile instead of downloading a ready-made service image.

This is mandatory in the project because each image must be created by the developer.

For the nginx service, the build context is:

```yaml
./requirements/nginx
```

which means Docker Compose will look for a Dockerfile inside that directory.

The same logic applies to:

Wordpress:
```yaml
./requirements/wordpress
```

MariaDB:
```yaml
./requirements/mariadb
```

This is an important design choice because it keeps the infrastructure reproducible and fully under the developer’s control.

Docker Compose does not build containers directly from source files. It builds images from Dockerfiles, and then creates containers from those images.

```yaml
    container_name: <name>
```

This field sets a fixed and explicit name for the container.

Without this field, Docker Compose would generate an automatic name based on the project and service.

Using explicit names makes debugging easier when using commands such as:

```bash
docker ps
```
```bash
docker logs
```
```bash
docker exec
```

All services applies this.

```yaml
    ports:
```

This field maps ports between the host machine and the container.

It is only used in the `nginx` service because NGINX must be the only entry point _exposed outside_ the Docker network.

```yaml
"443:443"
```

This mapping means:

- port 443 on the host machine

- is forwarded to port 443 inside the NGINX container

This is required because the subject states that the infrastructure must be reachable only through port 443 using TLS.

_No other service should expose ports to the host._

```yaml
    volumes:
```
inside a service.

When volumes appears inside a service definition, it means a storage area is attached to that container.

This is used to persist important files outside the container’s ephemeral filesystem.

If a container is deleted and recreated, the data stored in the volume remains available.

```yaml
      - wordpress_data:/var/www/html
```

This line means:

- wordpress_data is the named volume managed by Docker.

- `/var/www/html` is the path inside the container where the volume is mounted.

This path is important because it is the directory where WordPress files are stored.

Both the `nginx` and `wordpress` services mount the same WordPress volume because:

- WordPress writes and updates website files there.

- NGINX needs access to those files to serve the site correctly.

```yaml
      - mariadb_data:/var/lib/mysql
```

This line mounts the MariaDB persistent volume into `/var/lib/mysql`, which is the standard directory where MariaDB stores its database files.

This ensures that the database survives container recreation.

```yaml
    networks:
```
inside a service

This field defines which Docker network the container joins.

In this project, all services join the same custom network called inception.

This allows internal communication between containers while keeping that communication isolated from unrelated containers.

```yaml
      - inception
```

This attaches the service to the custom inception network.

Because all three services share this network, they can communicate using service names as internal hostnames.

For example:

- NGINX can reach WordPress using wordpress.

- WordPress can reach MariaDB using mariadb.

This is one of the reasons service names matter in Docker Compose.

```yaml
    depends_on:
```

This field expresses startup dependency order between services.

It tells Docker Compose which service should be started first.

For example:

- NGINX depends on WordPress.

- WordPress depends on MariaDB.

This improves startup sequencing and reflects the logical structure of the infrastructure.

However, depends_on does not mean that the dependent service is fully ready to accept connections. It only means its container has been started.

That distinction is important in practice.

For this reason, services often implement their own waiting logic (for example, retrying database connections) instead of relying only on `depends_on`.

```yaml
    restart: always
```

This field tells Docker to automatically restart the container if it stops unexpectedly.

It is used to satisfy the project requirement that containers must restart in case of a crash.

This makes the infrastructure more resilient and avoids manual recovery after failures or host reboots.

```yaml
    env_file:
```

This field loads environment variables from a separate file.

It is used in services that need configuration values such as usernames, passwords, database names, or domain names.

Using an external .env file avoids hardcoding configuration directly in the Compose file.

This is mandatory in the project.

```yaml
      - .env
```

This means the service will load variables from the .env file located next to docker-compose.yml.

Typical variables stored there include:

- database name

- database user

- domain name

- WordPress user configuration

Sensitive credentials should not be encrypted in Dockerfiles or the .env and will be stored in the following field:

```yaml
    secrets:
```
inside a service.

In this field we will define where we will get the passwords from.

```yaml
      - db_password
      - db_root_password
```

Each secret:

- has a name (db_password, db_root_password).

- is linked to a file stored on the host machine.

- is not exposed in plain text inside the Compose file.

```yaml
networks:
```
at global level

This section defines the custom Docker networks created for the project.

A dedicated network is required because containers need to communicate with each other internally in a controlled and isolated way.

```yaml
    inception:
```

This is the name of the project network.

All services are attached to this network so they can exchange traffic internally.

Using a custom network is also important because network: host, links, and --link are forbidden by the subject.

```yaml
      driver: bridge
```

The bridge driver is the standard Docker network driver for containers running on the same host.

It provides:

- internal communication between containers.

- name resolution by service name.

- isolation from the host network.

This is the appropriate choice for the mandatory part of the project.

```yaml
volumes:
```
at global level

This section defines the named volumes used by the project.

A named volume is managed by Docker and is used to persist data independently from the lifecycle of a container.

This is required because containers are disposable, but website files and database data must survive rebuilds and restarts.

```yaml
  wordpress_data:
```
and
```yaml
  mariadb_data:
```
These are the names of the two persistent Docker volumes used in the project.

They store:

- WordPress website files.

- MariaDB database files.

The subject explicitly requires two named volumes for these persistent storages.

```yaml
    driver: local
```

This tells Docker to use the local volume driver.

This is the default and standard choice for local persistent storage on the same machine.

```yaml
    driver_opts:
```

This field provides additional options to control how the local volume behaves.

It is used here to force the data to be physically stored in a specific directory on the host machine.

```yaml
      type: none
```

This option indicates that no special filesystem type is being requested.

It is part of the low-level local driver configuration.

```yaml
      o: bind
```

This tells the local volume driver to bind the volume storage to a specific host path.

Even though this internally relies on bind behavior, it is still declared as a Docker named volume in the Compose file, which is why it is used to satisfy the subject requirement.

Thwe important point is that the service mounts a named volume, not a direct bind mount written inline in the service definition.

```yaml
      device:
```

This sets the real host path where the volume data is stored.

This is required by the subject, which states that both named volumes must store their data under /home/login/data on the host machine.

Wordpress volume:
```yaml
/home/<login>/data/wordpress
```

MariaDB volume:
```yaml
/home/<login>/data/mariadb
```

Before launching the project, these directories must exist on the host system and use the correct login name.

```yaml
secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
```
at global level.

Docker secrets are used to securely manage sensitive information such as passwords.

Instead of storing credentials inside the Dockerfiles or directly in the `docker-compose.yml`, secrets are stored in external files and injected into containers at runtime.

This approach improves security and follows best practices required by the project.

Secrets must be explicitly attached to the services that need them.

MariaDB needs:
- the database user password
```yaml
  db_password
```

- the root password
```yaml
  db_root_password
```

WordPress only needs:
- the database user password to connect to MariaDB.
```yaml
  db_password
```

_Why Secrets Are Used Instead of Environment Variables_

Environment variables are easier to use but less secure because:

- They can be exposed in logs.

- They can be accessed through container inspection.

- They may be accidentally committed.

Docker secrets provide:

- Better isolation.

- Runtime-only access.

- Reduced exposure of sensitive data.

For this reason:

- `.env` is used for configuration values (non-sensitive).

- `secrets` are used for passwords and credentials.

_Important Requirement_

Sensitive data must never be:

- Hardcoded in Dockerfiles.

- Written directly in docker-compose.yml.

- Committed to the Git repository.

Using Docker secrets helps satisfy this requirement.

---
---
---

## Step 4: Dockerfiles

Dockerfiles are used to define how a Docker image is built.

They describe:

- The base system used.
- Which software is installed.
- Which files are copied into the image.
- Which command is executed when the container starts.

Each service in the project (nginx, wordpress, mariadb) has its own Dockerfile.

---
* ### _MariaDB Dockerfile_

The MariaDB image is built from:

```bash
srcs/requirements/mariadb/Dockerfile
```

_Content:_

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./conf/mariadb-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/mariadb.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb.sh

ENTRYPOINT ["/usr/local/bin/mariadb.sh"]
```

_Explanation:_

```dockerfile
FROM debian:bookworm-slim
```

Defines the base image used to build the container.

```dockerfile 
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y mariadb-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

Installs MariaDB and cleans unnecessary package data to reduce image size.

```dockerfile
COPY ./conf/mariadb-server.cnf /etc/mysql/mariadb.conf.d/
```

Copies the MariaDB configuration file into the container.

```dockerfile
COPY ./tools/mariadb.sh /usr/local/bin/
```

Copies the startup script used to initialize and launch MariaDB.

```dockerfile
RUN chmod +x /usr/local/bin/mariadb.sh
```

Makes the script executable.

```dockerfile 
ENTRYPOINT ["/usr/local/bin/mariadb.sh"]
```

Defines the command executed when the container starts.

---

* ### _WordPress Dockerfile_

The WordPress image is built from:

```bash
srcs/requirements/wordpress/Dockerfile
```

_Content:_

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    php-fpm \
    php-mysql \
    curl \
    mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY ./tools/wordpress.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/wordpress.sh

ENTRYPOINT ["/usr/local/bin/wordpress.sh"]
```

_Explanation:_

```dockerfile
FROM debian:bookworm-slim
```

Defines the base image.

```dockerfile
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    php-fpm \
    php-mysql \
    curl \
    mariadb-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

Installs PHP-FPM and required dependencies to run WordPress and connect to MariaDB.

```dockerfile
COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
```

Copies the PHP-FPM configuration file.

```dockerfile
COPY ./tools/wordpress.sh /usr/local/bin/
```

Copies the startup script responsible for configuring WordPress.

```dockerfile
RUN chmod +x /usr/local/bin/wordpress.sh
```

Makes the script executable.

```dockerfile
ENTRYPOINT ["/usr/local/bin/wordpress.sh"]
```

Defines the startup command of the container.

---

* ### _NGINX Dockerfile_

The NGINX image is built from:

```bash
srcs/requirements/nginx/Dockerfile
```

_Content:_

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nginx openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./conf/nginx.conf /etc/nginx/sites-available/default
COPY ./tools/nginx.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/nginx.sh

ENTRYPOINT ["/usr/local/bin/nginx.sh"]
```
_Explanation:_

```dockerfile
FROM debian:bookworm-slim
```

Defines the base image.

```dockerfile
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nginx openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

Installs NGINX and OpenSSL for HTTPS support.

```dockerfile
COPY ./conf/nginx.conf /etc/nginx/sites-available/default
```

Copies the NGINX configuration file.

```dockerfile
COPY ./tools/nginx.sh /usr/local/bin/
```

Copies the startup script used to launch NGINX.

```dockerfile
RUN chmod +x /usr/local/bin/nginx.sh
```

Makes the script executable.

```dockerfile
ENTRYPOINT ["/usr/local/bin/nginx.sh"]
```
Defines the command executed when the container starts.
