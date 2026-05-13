*This project has been created as part of the 42 curriculum by jrubio-m.*

# Inception

## Description

Inception is a 42 system administration project whose goal is to build a small, reproducible web infrastructure with Docker. The project runs a WordPress website served through NGINX over HTTPS, with PHP-FPM processing dynamic content and MariaDB storing the application data.

The infrastructure is composed of three custom Docker images:

- **NGINX**: the only public entry point, exposed on port `443` with a self-signed TLS certificate.
- **WordPress**: a PHP-FPM container that downloads, configures, and installs WordPress using WP-CLI.
- **MariaDB**: the database container used by WordPress.

The services are orchestrated with Docker Compose, connected through a private Docker network, and backed by persistent storage mounted from the host machine.

## Project Description

This project uses Docker to isolate each service in its own container. Docker Compose is used to define how the containers are built, connected, started, and stopped as one infrastructure.

The main Compose file is:

```text
srcs/docker-compose.yml
```

The project sources are organized by service:

```text
srcs/requirements/nginx/Dockerfile
srcs/requirements/nginx/conf/nginx.conf

srcs/requirements/wordpress/Dockerfile
srcs/requirements/wordpress/conf/www.conf
srcs/requirements/wordpress/tools/wordpress.sh

srcs/requirements/mariadb/Dockerfile
srcs/requirements/mariadb/conf/mariadb-server.cnf
srcs/requirements/mariadb/tools/mariadb.sh
```

The main design choices are:

- One service per container, following the separation expected by the subject.
- Debian Bookworm Slim as the base image for all custom images.
- NGINX is the only service exposed to the host, so WordPress and MariaDB remain internal.
- WordPress and MariaDB communicate through a dedicated bridge network named `inception`.
- Database and WordPress files are persisted in host directories under `~/data`.
- Passwords are provided through Docker secrets instead of being stored in `.env`.
- Non-sensitive configuration, such as database name and WordPress usernames, is kept in `srcs/.env`.

### Virtual Machines vs Docker

A virtual machine runs a full guest operating system on top of a hypervisor. It provides strong isolation, but it is heavier because each VM needs its own kernel, system services, disk, memory, and boot process.

Docker containers share the host kernel and isolate applications using Linux features such as namespaces and control groups. Containers are lighter, start faster, and are easier to reproduce from Dockerfiles. In this project, Docker is the right choice because the goal is to package individual services, not to emulate several complete machines.

### Secrets vs Environment Variables

Environment variables are simple and convenient, but they are visible through container inspection and process environments. They are better suited for non-sensitive values such as `DB_NAME`, `DB_USER`, `WP_TITLE`, or WordPress usernames.

Docker secrets are mounted as files inside the container under `/run/secrets/`. This keeps passwords out of the Compose environment and separates sensitive data from normal configuration. This project uses secrets for the MariaDB root password, the MariaDB user password, the WordPress admin password, and the WordPress user password.

### Docker Network vs Host Network

A Docker bridge network creates an isolated internal network for the containers. Containers can reach each other by service name, such as `wordpress` or `mariadb`, while remaining hidden from the host unless ports are explicitly published.

Host networking removes that isolation by making containers use the host network stack directly. This can be useful in specific performance or low-level networking cases, but it exposes more surface area and makes port conflicts more likely.

This project uses a Docker bridge network so that only NGINX exposes port `443`, while WordPress and MariaDB stay private.

### Docker Volumes vs Bind Mounts

Docker volumes are managed by Docker and are the standard way to persist container data. Bind mounts map a specific host path into a container, which gives direct control over where the data is stored on the host.

This project defines named volumes in Compose, but configures them with the local driver and bind options so they point to explicit host directories:

```text
~/data/wordpress
~/data/mariadb
```

This keeps the Compose structure clean while making the persisted data easy to find and remove during correction or local testing.

## Instructions

### Requirements

Docker and Docker Compose must be installed before running the project.

Check Docker:

```bash
docker --version
```

Check Docker Compose:

```bash
docker compose version
```

The local domain must also be added to `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add this line:

```text
127.0.0.1 jrubio-m.42.fr
```

### Setup

From the repository root, create the environment file, secret files, and host data directories:

```bash
make setup
```

This creates:

```text
srcs/.env
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_password.txt
~/data/mariadb
~/data/wordpress
```

The `.env` file contains non-sensitive values:

```env
DB_NAME=test
DB_USER=usertest
WP_TITLE=Inception
WP_ADMIN_USER=wpadtest
WP_ADMIN_EMAIL=wpad@wp.wp
WP_USER=wptest
WP_USER_EMAIL=wp@wp.wp
```

Each secret file must contain exactly one password. The files are created empty for repository correction, so they must be filled before starting the containers.

### Build and Run

Start the infrastructure:

```bash
make all
```

When the containers are running, open:

```text
https://jrubio-m.42.fr
```

The browser may show a warning because the TLS certificate is self-signed. Accept the warning to access the WordPress site.

The WordPress administration panel is available at:

```text
https://jrubio-m.42.fr/wp-admin
```

The admin username is the value of `WP_ADMIN_USER` in `srcs/.env`. The admin password is read from the `wp_admin_password` Docker secret.

### Stop and Clean

Stop the containers:

```bash
make down
```

Remove containers, images, Compose volumes, generated environment files, secrets, and local persistent data:

```bash
make fclean
```

Rebuild from a clean state:

```bash
make re
```

## Resources

- Docker documentation: used to understand images, containers, Dockerfiles, volumes, networks, and container lifecycle.
- Docker Compose documentation: used to define and run the multi-container infrastructure.
- Docker secrets documentation: used to provide passwords to containers through files in `/run/secrets/`.
- NGINX documentation: used to configure HTTPS, TLS certificates, server blocks, static file serving, and FastCGI forwarding.
- MariaDB documentation: used to configure the database server, create users, grant privileges, and allow access from the Docker network.
- WordPress documentation: used to understand WordPress installation, `wp-config.php`, users, and administration.
- WP-CLI documentation: used to automate WordPress download, configuration, installation, and user creation.
- PHP-FPM documentation: used to configure PHP-FPM and make it listen on port `9000` for NGINX.

### Use of AI

AI was used as a learning, debugging, and documentation assistant during the project. It was used to clarify Docker concepts, compare Docker networks and storage options, explain the role of each service, review Dockerfile structure, debug MariaDB initialization logic, understand the WordPress setup script, explain PHP-FPM and NGINX FastCGI configuration, and organize this README.

AI was not used to blindly generate the final project. The configuration files, scripts, and infrastructure behavior were reviewed, tested, and adapted manually.
