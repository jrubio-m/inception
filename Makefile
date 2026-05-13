all: check
	@echo "Starting..."
	@docker compose -f srcs/docker-compose.yml up

down:
	@echo "Shutting down..."
	@docker compose -f srcs/docker-compose.yml down

setup:
	@echo "Setting up the environment"
	@chmod +x ./srcs/requirements/tools/setup.sh
	@./srcs/requirements/tools/setup.sh
	@mkdir -p ~/data/mariadb
	@mkdir -p ~/data/wordpress

check:
	@test -f ./srcs/.env || (echo "Missing ./srcs/.env. Run 'make setup' first." && exit 1)
	@test -f ./secrets/db_password.txt && test -f ./secrets/db_root_password.txt && test -f ./secrets/wp_password.txt && test -f ./secrets/wp_admin_password.txt || (echo "Missing password files. Run 'make setup' first." && exit 1)
	@test -s ./srcs/.env || (echo "Empty ./srcs/.env. Empty ./srcs/.env. You can fill it out manually or run 'make setup' before running 'make all'." && exit 1)
	@test -s ./secrets/db_password.txt && test -s ./secrets/db_root_password.txt && test -s ./secrets/wp_password.txt && test -s ./secrets/wp_admin_password.txt || (echo "Empty password files. Add a password before running 'make all'." && exit 1)
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
	@rm -rf ~/data/mariadb
	@rm -rf ~/data/wordpress

re: fclean setup all
