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

* ### _Base directories_

Create the base directories:
```bash
mkdir -p ~/inception/srcs/requirements/mariadb/tools
mkdir -p ~/inception/srcs/requirements/mariadb/conf
mkdir -p ~/inception/srcs/requirements/wordpress/tools
mkdir -p ~/inception/srcs/requirements/wordpress/conf
mkdir -p ~/inception/srcs/requirements/nginx/conf
mkdir -p ~/inception/secrets
```

* ### _Volumes_

Create the directories where the volumes will be stored
```bash
mkdir -p ~/data/mariadb
mkdir -p ~/data/wordpress
```

* ### _Secrets and Environment_

Now we need to create the secrets and environment files (Only for tests. This can't be upload in the repo)
```bash
printf "" > ~/inception/secrets/db_password.txt
printf "" > ~/inception/secrets/db_root_password.txt
printf "" > ~/inception/secrets/wp_password.txt
printf "" > ~/inception/secrets/wp_admin_password.txt
chmod 600 ~/inception/secrets/db_password.txt ~/inception/secrets/db_root_password.txt ~/inception/secrets/wp_password.txt ~/inception/secrets/wp_admin_password.txt
touch ~/inception/srcs/.env
```

The "password" files must contain:
- Only the password we want to use in each case.
- They are created empty on purpose so no password is stored in the repository correction version.
- After creating them, each file must be filled manually before running the containers.

The ".env" file must contain:
- DB_NAME=test
- DB_USER=usertest

- WP_TITLE=Inception
- WP_ADMIN_USER=wpadtest
- WP_ADMIN_EMAIL=wpad@wp.wp
- WP_USER=wptest
- WP_USER_EMAIL=wp@wp.wp

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
      - wp_password
      - wp_admin_password
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
      device: ~/data/wordpress

  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ~/data/mariadb

secrets:
  db_password:
    file: ../secrets/db_password.txt
  db_root_password:
    file: ../secrets/db_root_password.txt
  wp_password:
    file: ../secrets/wp_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
```

---

* ### _Explanation_

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

The important point is that the service mounts a named volume, not a direct bind mount written inline in the service definition.

```yaml
      device:
```

This sets the real host path where the volume data is stored.

This is required by the subject, which states that both named volumes must store their data under the login user's data directory on the host machine.

Wordpress volume:
```yaml
~/data/wordpress
```

MariaDB volume:
```yaml
~/data/mariadb
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

WordPress needs:
- the database user password to connect to MariaDB.
```yaml
  db_password
```

- the admin password to install the WordPress administrator.
```yaml
  wp_admin_password
```

- the regular user password.
```yaml
  wp_password
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
    rm -rf /var/lib/apt/lists/* \
    rm -rf /var/lib/mysql/*

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
    rm -rf /var/lib/apt/lists/* \
    rm -rf /var/lib/mysql/*
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

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY ./tools/wordpress.sh /usr/local/bin/wordpress.sh

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
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
```

Installs WP-CLI, which is used by `wordpress.sh` to download and configure WordPress.

```dockerfile
COPY ./conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
```

Copies the PHP-FPM configuration file.

```dockerfile
COPY ./tools/wordpress.sh /usr/local/bin/wordpress.sh
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

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes \
        -out /etc/nginx/ssl/nginx.crt \
        -keyout /etc/nginx/ssl/nginx.key \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=42/CN=jrubio-m.42.fr" \
        -newkey rsa:2048 \
        -days 365

COPY ./conf/nginx.conf /etc/nginx/sites-available/default

CMD ["nginx", "-g", "daemon off;"]
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
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes \
        -out /etc/nginx/ssl/nginx.crt \
        -keyout /etc/nginx/ssl/nginx.key \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=42/CN=jrubio-m.42.fr" \
        -newkey rsa:2048 \
        -days 365
```

Creates the self-signed TLS certificate used by NGINX.

```dockerfile
COPY ./conf/nginx.conf /etc/nginx/sites-available/default
```

Copies the NGINX configuration file.

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```
Defines the command executed when the container starts.

## Step 5: Configuration files, scripts and entrypoints

* ### _mariadb-server.cnf_ 

The goal of mariadb-server.cnf is:

- Let MariaDB listen within the Docker network.
- Use `/var/lib/mysql` as a data directory.
- Do not depend on localhost.
- Be compatible with WordPress/PHP.

* ### _mariadb.sh_

This script is responsible for initializing and starting the MariaDB server inside the container.

- Enable strict mode with `set -e` to stop execution on errors.
- Create the `/run/mysqld` directory and assign proper permissions so MariaDB can create its socket and PID files.
- Read database passwords from Docker secrets.
- Check if the database has already been initialized by verifying the existence of `/var/lib/mysql/mysql`.
- If not initialized:
  - Run `mysql_install_db` to create the initial database structure.
  - Start MariaDB temporarily using `mysqld_safe` in the background.
  - Wait for the server to be ready.
  - Execute SQL commands to:
    - Set the root password
    - Create the application database
    - Create a user accessible from any host (`'%'`)
    - Grant privileges on the database
  - Shut down the temporary MariaDB instance using `mysqladmin`.
- Finally, start MariaDB in the foreground using `exec mysqld` so it becomes the main container process.
* ### _www.conf_ 
* ### _wordpress.sh_
* ### _nginx.conf_

---
---
---

## Step 6: Makefile

The `Makefile` is used to simplify the commands needed to prepare, run, stop, clean, and rebuild the project.

It must be executed from the root of the repository.

* ### _all_

```make
all: check
	@echo "Starting the app"
	@docker compose -f srcs/docker-compose.yml up
```

This is the main target.

It first runs `check` to verify that the required files exist, then starts the infrastructure using Docker Compose.

The Compose file is located at:

```bash
srcs/docker-compose.yml
```

Run it with:

```bash
make all
```

* ### _down_

```make
down:
	@echo "Shutting down the app"
	@docker compose -f srcs/docker-compose.yml down
```

This target stops and removes the containers and network created by Docker Compose.

It does not remove Docker volumes or the persistent data stored in `~/data`.

Run it with:

```bash
make down
```

* ### _setup_

```make
setup:
	@echo "Setting up the environment"
	@echo "\
	DB_NAME=test\
	\nDB_USER=usertest\
\
	\nWP_TITLE=Inception\
	\nWP_ADMIN_USER=wpadtest\
	\nWP_ADMIN_EMAIL=wpad@wp.wp\
\
	\nWP_USER=wptest\
	\nWP_USER_EMAIL=wp@wp.wp" > ./srcs/.env
	@mkdir -p ./secrets
	@printf "" > ./secrets/db_password.txt
	@printf "" > ./secrets/db_root_password.txt
	@printf "" > ./secrets/wp_password.txt
	@printf "" > ./secrets/wp_admin_password.txt
	@chmod 600 ./secrets/db_password.txt ./secrets/db_root_password.txt ./secrets/wp_password.txt ./secrets/wp_admin_password.txt
	@echo "Secret files were created empty. Fill them manually before running 'make all'."
	@mkdir -p ~/data/mariadb
	@mkdir -p ~/data/wordpress
```

This target prepares the local test environment.

It creates:

- `srcs/.env`, with non-sensitive configuration values.
- `secrets/db_password.txt`, containing the database user password.
- `secrets/db_root_password.txt`, containing the MariaDB root password.
- `secrets/wp_password.txt`, containing the regular WordPress user password.
- `secrets/wp_admin_password.txt`, containing the WordPress administrator password.
- `~/data/mariadb`, used by the MariaDB volume.
- `~/data/wordpress`, used by the WordPress volume.

The password files are created empty on purpose, so no password is stored in the repository correction version.

Before running `make all`, each secret file must be filled manually with the password it represents.

For local testing only, the empty `printf ""` values in the `Makefile` can be temporarily replaced with real passwords so `make setup` creates the secret files already filled.

This must never be committed or submitted with real passwords.

The password files are created with `chmod 600` so only the owner can read and write them.

Run it with:

```bash
make setup
```

* ### _check_

```make
check:
	@test -f ./srcs/.env || (echo "Missing ./srcs/.env. Run 'make setup' first." && exit 1)
	@test -f ./secrets/db_password.txt || (echo "Missing ./secrets/db_password.txt. Run 'make setup' first." && exit 1)
	@test -f ./secrets/db_root_password.txt || (echo "Missing ./secrets/db_root_password.txt. Run 'make setup' first." && exit 1)
	@test -f ./secrets/wp_password.txt || (echo "Missing ./secrets/wp_password.txt. Run 'make setup' first." && exit 1)
	@test -f ./secrets/wp_admin_password.txt || (echo "Missing ./secrets/wp_admin_password.txt. Run 'make setup' first." && exit 1)
	@test -s ./secrets/db_password.txt || (echo "Empty ./secrets/db_password.txt. Add a password before running 'make all'." && exit 1)
	@test -s ./secrets/db_root_password.txt || (echo "Empty ./secrets/db_root_password.txt. Add a password before running 'make all'." && exit 1)
	@test -s ./secrets/wp_password.txt || (echo "Empty ./secrets/wp_password.txt. Add a password before running 'make all'." && exit 1)
	@test -s ./secrets/wp_admin_password.txt || (echo "Empty ./secrets/wp_admin_password.txt. Add a password before running 'make all'." && exit 1)
	@mkdir -p ~/data/mariadb
	@mkdir -p ~/data/wordpress
```

This target checks that the required `.env` and secret files exist before starting Docker Compose.

It also checks that every secret file is non-empty.

It prevents Docker from failing later with bind mount errors caused by missing secret files.

It also ensures that the persistent data directories exist.

Run it with:

```bash
make check
```

* ### _clean_

```make
clean:
	@echo "Cleaning volumes, containers and images"
	@docker compose -f srcs/docker-compose.yml down -v
	@docker rm -vf mariadb
	@docker rm -vf wordpress
	@docker rm -vf nginx
	@docker rmi -f srcs-mariadb
	@docker rmi -f srcs-wordpress
	@docker rmi -f srcs-nginx
	@docker images
	@docker ps -a
```

This target removes the Docker Compose environment, including named Docker volumes, containers, and the project images.

It also prints the remaining Docker images and containers for debugging.

Run it with:

```bash
make clean
```

* ### _fclean_

```make
fclean: clean
	@echo "Cleaning env"
	@rm -f ./srcs/.env
	@rm -rf secrets
	@sudo rm -rf ~/data/mariadb
	@sudo rm -rf ~/data/wordpress
```

This target runs `clean` first, then removes the local environment files and host data directories.

It deletes:

- `srcs/.env`
- `secrets/`
- `~/data/mariadb`
- `~/data/wordpress`

Because the data directories may contain files created by containers, `sudo` is used to remove them.

Run it with:

```bash
make fclean
```

* ### _re_

```make
re: fclean setup all
```

This target performs a full rebuild from a clean state.

It runs:

1. `fclean`
2. `setup`
3. `all`

Run it with:

```bash
make re
```

---
---
---

## Step 7: Test and run

* ### _Util commands_
```bash
docker compose down -v
docker rmi srcs-mariadb:latest 
docker rmi srcs-wordpress:latest 
sudo rm -rf ~/data/mariadb/*
sudo rm -rf ~/data/wordpress/*
```
