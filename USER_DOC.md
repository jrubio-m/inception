
* ### _.env_

Command to insert the minimum variables in .env that the file must contain:

```bash

echo "DOMAIN_NAME=<login>.42.fr

DB_NAME=
DB_USER=
DB_HOST=

WP_TITTLE=Inception
WP_ADMIN_USER=
WP_ADMIN_EMAIL=
WP_USER=
WP_USER_EMAIL=
" > ~/inception/.env

```
* ### _secrets_

Command for create the password files you will need:
```bash

touch db_password.txt db_root_password.txt wp_password.txt wp_admin_password.txt

```
