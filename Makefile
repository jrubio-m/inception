all: check
	@echo "Starting the app"
	@docker compose -f srcs/docker-compose.yml up

down:
	@echo "Shutting down the app"
	@docker compose -f srcs/docker-compose.yml down

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

fclean: clean
	@echo "Cleaning env"
	@rm -f ./srcs/.env
	@rm -rf secrets
	@sudo rm -rf ~/data/mariadb
	@sudo rm -rf ~/data/wordpress


re: fclean setup all
