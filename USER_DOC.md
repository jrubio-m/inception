
* ### _.env_

Command to create the minimum environment and secret files for a local test:

```bash
make setup
```

This creates `srcs/.env`, the `secrets/` files, and the local data directories used by the Docker volumes.

The `.env` file must contain only non-sensitive values:

```env
DB_NAME=test
DB_USER=usertest
WP_TITLE=Inception
WP_ADMIN_USER=wpadtest
WP_ADMIN_EMAIL=wpad@wp.wp
WP_USER=wptest
WP_USER_EMAIL=wp@wp.wp
```

* ### _secrets_

The password files are stored at the root of the repository:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_password.txt
secrets/wp_admin_password.txt
```

Each file must contain only the corresponding password.

For repository correction, `make setup` creates these files empty so no password is stored in the submitted version.
After running `make setup`, open each file and write the password that must be used by that secret before running `make all`.

For local testing only, you can temporarily replace the empty `printf ""` values in the `Makefile` with your own passwords.
This makes `make setup` create the secret files already filled, but the `Makefile` must not be committed or submitted with real passwords.
