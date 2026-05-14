# User Documentation

This document explains how to use and administer the Inception stack.

## Provided Services

The project starts three services with Docker Compose:

- **NGINX**: receives HTTPS requests from the browser and serves the WordPress site. It is the only service exposed to the host machine, on port `443`.
- **WordPress**: runs the website application with PHP-FPM. It communicates with NGINX and MariaDB inside the Docker network.
- **MariaDB**: stores the WordPress database. It is only available inside the Docker network and is not directly exposed to the host.

The website files are stored in:

```text
~/data/wordpress
```

The database files are stored in:

```text
~/data/mariadb
```

## First Setup

From the project root, create the required configuration files, secret files, and data directories:

```bash
make setup
```

This creates:

```text
srcs/.env
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_password.txt
secrets/wp_admin_password.txt
~/data/wordpress
~/data/mariadb
```

Before starting the project, fill each secret file with the correct password. Each file must contain only one password.

The generated `srcs/.env` file contains non-sensitive values:

```env
DB_NAME=wordpress
DB_USER=user
DB_HOST=mariadb
DB_PORT=3306

WP_TITLE=Inception
WP_ADMIN_USER=jrubio-m-ad
WP_ADMIN_EMAIL=wpad@example.ex

WP_USER=jrubio-m
WP_USER_EMAIL=wp@example.ex
```

Passwords must not be stored in `srcs/.env`.

## Start the Project

Start the stack from the project root:

```bash
make all
```

This command checks that the `.env` file and all secret files exist and are not empty. Then it starts the Docker Compose stack.

If the command reports empty password files, open the files in `secrets/`, add the passwords, and run `make all` again.

## Stop the Project

Stop the running containers:

```bash
make down
```

This stops the services but keeps the persistent WordPress and MariaDB data.

To remove containers, images, generated secrets, the `.env` file, and local persistent data:

```bash
make fclean
```

Use `make fclean` only when you want to reset the project completely.

## Access the Website

The local domain must point to the local machine. Check `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

It must contain:

```text
127.0.0.1 jrubio-m.42.fr
```

After the containers are running, open the website:

```text
https://jrubio-m.42.fr
```

The browser may show a warning because the TLS certificate is self-signed. Accept the warning to continue.

## Access the Administration Panel

Open the WordPress administration panel:

```text
https://jrubio-m.42.fr/wp-admin
```

The administrator username is defined in `srcs/.env`:

```env
WP_ADMIN_USER=jrubio-m-ad
```

The administrator password is stored in:

```text
secrets/wp_admin_password.txt
```

## Credentials

The credentials are split between `srcs/.env` and the `secrets/` directory.

The `.env` file stores only non-sensitive values:

- `DB_NAME`: database name.
- `DB_USER`: MariaDB user used by WordPress.
- `DB_HOST`: MariaDB service hostname.
- `DB_PORT`: MariaDB service port.
- `WP_TITLE`: WordPress site title.
- `WP_ADMIN_USER`: WordPress administrator username.
- `WP_ADMIN_EMAIL`: WordPress administrator email.
- `WP_USER`: regular WordPress username.
- `WP_USER_EMAIL`: regular WordPress user email.

The `secrets/` directory stores passwords:

- `secrets/db_password.txt`: password for `DB_USER`.
- `secrets/db_root_password.txt`: MariaDB root password.
- `secrets/wp_password.txt`: password for the regular WordPress user.
- `secrets/wp_admin_password.txt`: password for the WordPress administrator.

To change credentials, update the corresponding `.env` value or secret file before the first WordPress and MariaDB initialization.

If the containers have already initialized the database and WordPress files, changing the files alone may not update existing users. In that case, reset the persistent data with:

```bash
make fclean
make setup
```

Then fill the secret files again and start the project with:

```bash
make all
```

## Check That Services Are Running

List running containers:

```bash
docker ps
```

You should see these containers:

```text
nginx
wordpress
mariadb
```

Check all containers, including stopped ones:

```bash
docker ps -a
```

Check service logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Check the Docker Compose status:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Check that the website responds:

```bash
curl -k https://jrubio-m.42.fr
```

The `-k` option is used because the project uses a self-signed TLS certificate.

## Common Problems

If `make all` says that `srcs/.env` is missing, run:

```bash
make setup
```

If `make all` says that password files are empty, fill every file inside `secrets/`.

If the website does not load, check that:

- Docker is running.
- The containers are running with `docker ps`.
- `/etc/hosts` contains `127.0.0.1 jrubio-m.42.fr`.
- Port `443` is not already being used by another service.
- The logs do not show errors in `nginx`, `wordpress`, or `mariadb`.
