# Developer Documentation

This document explains how to set up, build, launch, inspect, and clean the Inception project as a developer.

## Project Overview

Inception is a Docker Compose infrastructure made of three custom services:

- **nginx**: HTTPS entry point exposed on host port `443`.
- **wordpress**: PHP-FPM service that installs and runs WordPress.
- **mariadb**: database service used by WordPress.

The services are defined in:

```text
srcs/docker-compose.yml
```

The service sources are stored in:

```text
srcs/requirements/nginx
srcs/requirements/wordpress
srcs/requirements/mariadb
```

## Prerequisites

The project needs:

- A Linux environment or virtual machine.
- `make`.
- Docker Engine.
- Docker Compose plugin.
- Permission to run Docker commands.

Check the installed tools:

```bash
make --version
docker --version
docker compose version
```

If Docker requires `sudo`, either run the Docker commands with `sudo` or add the current user to the `docker` group:

```bash
sudo usermod -aG docker $USER
```

After changing the Docker group, log out and log back in.

Adding a user to the `docker` group gives that user root-level control through Docker. This is acceptable for a local development VM, but it should be treated carefully.

## Environment Setup From Scratch

Clone or place the repository on the machine, then enter the project root:

```bash
cd inception
```

Create the generated configuration, secret files, and persistent data directories:

```bash
make setup
```

This runs:

```text
srcs/requirements/tools/setup.sh
```

The setup script creates:

```text
srcs/.env
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_password.txt
secrets/wp_admin_password.txt
~/data/mariadb
~/data/wordpress
```

The generated `srcs/.env` file contains only non-sensitive configuration:

```env
DB_NAME=wordpress
DB_USER=jrubio-m

WP_TITLE=Inception
WP_ADMIN_USER=jrubio-m-ad
WP_ADMIN_EMAIL=wpad@example.ex

WP_USER=wpuser
WP_USER_EMAIL=wp@example.ex
```

The secret files are created empty on purpose. Fill each one before launching the stack:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_password.txt
secrets/wp_admin_password.txt
```

Each secret file must contain only one password. Do not store passwords in `srcs/.env`.

## Local Domain Configuration

The project is configured for this domain:

```text
jrubio-m.42.fr
```

Add it to `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add:

```text
127.0.0.1 jrubio-m.42.fr
```

## Build and Launch

Build and start the project with the Makefile:

```bash
make all
```

The `all` target runs the `check` target first. The check verifies that:

- `srcs/.env` exists.
- All four secret files exist.
- `srcs/.env` is not empty.
- All four secret files are not empty.
- `~/data/mariadb` and `~/data/wordpress` exist.

Then it launches Docker Compose with:

```bash
docker compose -f srcs/docker-compose.yml up
```

The containers run in the foreground. Stop them with `Ctrl+C`, or use another terminal and run:

```bash
make down
```

## Makefile Targets

Use these commands from the project root:

```bash
make setup
```

Creates `srcs/.env`, empty secret files, and host data directories.

```bash
make all
```

Checks the configuration and starts the Compose stack.

```bash
make down
```

Stops and removes the running Compose containers, while keeping images and persistent data.

```bash
make clean
```

Stops the Compose stack, removes Compose volumes, removes the project containers, and removes the custom images.

```bash
make fclean
```

Runs `clean`, then removes `srcs/.env`, the `secrets/` directory, and the persistent data directories under `~/data`.

```bash
make re
```

Runs `fclean`, then `setup`, then `all`.

## Docker Compose Services

The Compose file defines three services.

### nginx

Build context:

```text
srcs/requirements/nginx
```

Main role:

- Installs NGINX and OpenSSL.
- Creates a self-signed TLS certificate.
- Serves the WordPress site over HTTPS.
- Forwards PHP requests to `wordpress:9000`.

Important configuration:

```text
srcs/requirements/nginx/conf/nginx.conf
```

Published port:

```text
443:443
```

### wordpress

Build context:

```text
srcs/requirements/wordpress
```

Main role:

- Installs PHP-FPM, PHP MySQL support, MariaDB client, curl, and WP-CLI.
- Waits for MariaDB to be ready.
- Downloads WordPress if it is not already present.
- Creates `wp-config.php`.
- Installs WordPress and creates users.
- Starts PHP-FPM in the foreground.

Important files:

```text
srcs/requirements/wordpress/conf/www.conf
srcs/requirements/wordpress/tools/wordpress.sh
```

### mariadb

Build context:

```text
srcs/requirements/mariadb
```

Main role:

- Installs MariaDB server.
- Initializes the database directory if needed.
- Creates the configured database and database user.
- Starts MariaDB in the foreground.

Important files:

```text
srcs/requirements/mariadb/conf/mariadb-server.cnf
srcs/requirements/mariadb/tools/mariadb.sh
```

## Container Management Commands

List running containers:

```bash
docker ps
```

List all containers:

```bash
docker ps -a
```

View Compose status:

```bash
docker compose -f srcs/docker-compose.yml ps
```

View logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Follow logs:

```bash
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb
```

Open a shell inside a container:

```bash
docker exec -it nginx sh
docker exec -it wordpress bash
docker exec -it mariadb bash
```

Inspect the Docker network:

```bash
docker network ls
docker network inspect srcs_inception
```

List Docker volumes:

```bash
docker volume ls
```

Inspect a project volume:

```bash
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

## Data Storage and Persistence

WordPress files persist in:

```text
~/data/wordpress
```

Inside the containers, this path is mounted as:

```text
/var/www/html
```

MariaDB data persists in:

```text
~/data/mariadb
```

Inside the MariaDB container, this path is mounted as:

```text
/var/lib/mysql
```

The Compose file defines named volumes:

```text
wordpress_data
mariadb_data
```

These named volumes use the local driver with bind options, so Docker manages them as Compose volumes while the actual data is stored in the explicit host directories under `~/data`.

Because of this persistence:

- Stopping containers with `make down` does not delete the website or database.
- Rebuilding images does not delete the website or database.
- Deleting `~/data/wordpress` removes WordPress files.
- Deleting `~/data/mariadb` removes the database.
- Running `make fclean` removes both persistent data directories.

## Secrets and Configuration

The Compose file loads non-sensitive values from:

```text
srcs/.env
```

It mounts passwords as Docker secrets from:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_password.txt
secrets/wp_admin_password.txt
```

Inside the containers, secrets are available under:

```text
/run/secrets/
```

The WordPress setup script reads:

```text
/run/secrets/db_password
/run/secrets/wp_password
/run/secrets/wp_admin_password
```

The MariaDB setup script reads:

```text
/run/secrets/db_password
/run/secrets/db_root_password
```

If credentials must be changed after the first initialization, update the files and then reset the persisted data:

```bash
make fclean
make setup
```

Fill the secret files again, then launch:

```bash
make all
```

## Useful Verification Commands

Check that the website answers over HTTPS:

```bash
curl -k https://jrubio-m.42.fr
```

Check that WordPress files exist on the host:

```bash
ls -la ~/data/wordpress
```

Check that MariaDB files exist on the host:

```bash
ls -la ~/data/mariadb
```

Check the active Compose configuration:

```bash
docker compose -f srcs/docker-compose.yml config
```

Check image names created by Compose:

```bash
docker images
```
