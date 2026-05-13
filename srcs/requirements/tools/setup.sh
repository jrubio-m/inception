#!/bin/sh

if [ ! -d "./srcs/requirements" ]; then
	echo "Error: run this script from the Inception project root."
	exit 1
fi

ENV_FILE="./srcs/.env"
SECRETS_DIR="./secrets"

cat > "$ENV_FILE" << EOF
DB_NAME=wordpress
DB_USER=jrubio-m

WP_TITLE=Inception
WP_ADMIN_USER=jrubio-m-ad
WP_ADMIN_EMAIL=wpad@example.ex

WP_USER=wpuser
WP_USER_EMAIL=wp@example.ex
EOF

mkdir -p "$SECRETS_DIR"

: > "$SECRETS_DIR/db_password.txt"
: > "$SECRETS_DIR/db_root_password.txt"
: > "$SECRETS_DIR/wp_password.txt"
: > "$SECRETS_DIR/wp_admin_password.txt"

chmod 600 \
	"$SECRETS_DIR/db_password.txt" \
	"$SECRETS_DIR/db_root_password.txt" \
	"$SECRETS_DIR/wp_password.txt" \
	"$SECRETS_DIR/wp_admin_password.txt"

echo "Secret files were created empty. Fill them manually before running 'make all'."

mkdir -p "$HOME/data/mariadb"
mkdir -p "$HOME/data/wordpress"