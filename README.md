*This project has been created as part of the 42 curriculum by **jrubio-m***
# Inception
## Description
Inception is a system administration project from the 42 curriculum.  

The goal of the project is to build a small Docker-based infrastructure composed of several services, each running in its own container.

The infrastructure includes:
- **NGINX** as the only entry point to the application, using HTTPS on port 443.
- **WordPress** running with PHP-FPM.
- **MariaDB** as the database server.
- **Docker volumes** to persist WordPress and database data.
- **Docker secrets** to handle sensitive passwords without storing them directly in the `.env` file.
- **A custom Docker network** to allow the containers to communicate with each other internally.

The final result is a WordPress website served through NGINX over TLS, with persistent data stored on the host machine.

## Project Description

This project uses Docker and Docker Compose to create and manage a multi-container environment.

Each service has its own Dockerfile:

- `srcs/requirements/nginx/Dockerfile`  
  Builds the NGINX image, installs NGINX and OpenSSL, creates a self-signed TLS certificate, and starts NGINX in the foreground.

- `srcs/requirements/wordpress/Dockerfile`  
  Builds the WordPress/PHP-FPM image, installs PHP-FPM, PHP MySQL extensions, MariaDB client, curl, and WP-CLI.

- `srcs/requirements/mariadb/Dockerfile`  
  Builds the MariaDB image, installs MariaDB server, copies the configuration file and initialization script, and starts MariaDB.

The main services are defined in:

```
srcs/docker-compose.yml
```

The project also includes configuration and initialization files:

```
srcs/requirements/nginx/conf/nginx.conf
srcs/requirements/wordpress/conf/www.conf
srcs/requirements/mariadb/conf/mariadb-server.cnf

srcs/requirements/wordpress/tools/wordpress.sh
srcs/requirements/mariadb/tools/mariadb.sh
```
## Instructions
### Requirements

Before running the project, make sure Docker and Docker Compose are installed.

To check if Docker is installed:

```bash
docker --version
```

To check if Docker Compose is installed:

```bash
docker compose version
```

If Docker is not installed, install it following the official Docker documentation for your operating system:

- Docker Engine installation documentation
- Docker Compose installation documentation

The following directories must exist on the host machine:

```bash
mkdir -p /home/jrubio-m/data/mariadb
mkdir -p /home/jrubio-m/data/wordpress
```
The local domain must be added to /etc/hosts:

```bash
sudo nano /etc/hosts
```
Add:

```bash
127.0.0.1 jrubio-m.42.fr
```

Create a secrets directory at the root of the repository:

```bash
mkdir -p secrets
```

Create the required secret files:

```bash
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_password.txt
```

Each file must contain the corresponding password.

Create the .env file inside srcs:

```bash
touch srcs/.env
```

must contain at least:

```
DOMAIN_NAME=jrubio-m.42.fr

DB_NAME=
DB_USER=
DB_HOST=

WP_TITLE=Inception
WP_ADMIN_USER=
WP_ADMIN_EMAIL=

WP_USER=
WP_USER_EMAIL=
```

Passwords must not be stored in .env.

### Build and Run

From the root of the repository, run:

`make`

Once the containers are running, open:

`https://jrubio-m.42.fr`

The browser may show a warning because the TLS certificate is self-signed.
Accept the warning to access the WordPress site.

Clean Persistent Data

To remove containers, volumes, and persistent data:

`make fclean`

### Usage

After starting the project, the WordPress website is available at:

https://jrubio-m.42.fr

The WordPress administration panel is available at:

https://jrubio-m.42.fr/wp-admin

The admin user is defined in the .env file:

`WP_ADMIN_USER=jrubio_admin`

The admin password is read from:

`/run/secrets/wp_admin_password`

inside the WordPress container.

## Resources
- Official Documentation
- Docker documentation
Used to understand Docker images, containers, volumes, networks, and Docker Compose.
- Docker Compose documentation
Used to define and manage the multi-container application.
- Docker Compose secrets documentation
Used to handle passwords through files mounted under /run/secrets.
- NGINX documentation
Used to configure HTTPS, server blocks, static file serving, and FastCGI forwarding.
- MariaDB documentation
Used to configure the database server, users, privileges, and remote access inside the Docker network.
- WordPress documentation
Used to understand WordPress installation, configuration, and the role of wp-config.php.
- WP-CLI documentation
Used to automate WordPress download, configuration, installation, and user creation.
- PHP-FPM documentation
Used to configure PHP-FPM and expose it on port 9000 for NGINX.

### Use of AI

AI was used as a learning and debugging assistant during the development of this project.

It was used to:

- Understand Docker concepts such as images, containers, networks, volumes, bind mounts, and secrets.
- Explain the role of each service in the infrastructure.
- Review and improve Dockerfiles.
- Understand and debug MariaDB initialization.
- Understand and debug the WordPress installation script.
- Explain PHP-FPM configuration.
- Explain NGINX configuration and the FastCGI connection between NGINX and WordPress.
- Help structure the project documentation.
- Find documentation more easily

AI was not used to blindly generate the final project without understanding.

Each configuration file and script was reviewed, tested, debugged, and adapted manually.
