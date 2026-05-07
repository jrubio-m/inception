FROM debian:bookworm-slim

RUN	apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y mariadb-server && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* \
	rm -rf /var/lib/mysql/*

COPY ./conf/mariadb-server.cnf /etc/mysql/mariadb.conf.d/
COPY ./tools/mariadb.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb.sh

ENTRYPOINT ["/usr/local/bin/mariadb.sh"]
