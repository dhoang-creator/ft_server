# **************************************************************************** #
#                                                                              #
#                                                         ::::::::             #
#    Dockerfile                                         :+:    :+:             #
#                                                      +:+                     #
#    By: dhoang <dhoang@student.codam.nl>             +#+                      #
#                                                    +#+                       #
#    Created: 2020/05/25 19:05:08 by dhoang        #+#    #+#                  #
#    Updated: 2020/06/08 13:40:03 by dhoang        ########   odam.nl          #
#                                                                              #
# **************************************************************************** #

# OS/BASE IMAGE
FROM debian:buster

# ROOT INSTALLS
RUN apt-get update
RUN apt-get -y upgrade
RUN apt-get -y install wget
RUN apt-get -y install default-mysql-server

# WORKDIR TO COPY INTO
WORKDIR /var/www/html

# SRCS -> WORKDIR
COPY srcs/user.ini .user.ini
COPY srcs/autoindex.sh .

# NGINX
RUN apt-get -y install nginx
COPY srcs/default /etc/nginx/sites-available/default

# REPEATEDLY REQUEST SSL CERT
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 			\
	-keyout		/etc/ssl/private/localhost.key 						\
	-out 		/etc/ssl/certs/localhost.crt						\
	-subj "/C=NL/ST=Noord-Holland/L=Amsterdam/O=Codam/CN=localhost"

# PHPMYADMIN
RUN apt-get -y install php7.3 php-mysql php-mbstring php-fpm php-gd php-cli php-zip
RUN mkdir phpmyadmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-english.tar.gz
RUN tar xf phpMyAdmin-5.0.2-english.tar.gz -C phpmyadmin --strip-components=1
RUN rm -f phpMyAdmin-5.0.2-english.tar.gz
COPY srcs/config.inc.php phpmyadmin/config.inc.php


# MYSQL & GRANTING OF PRIVILEGES
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp	
RUN service mysql start && \
	mysql < phpmyadmin/sql/create_tables.sql -u root && \
	mysql -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost' IDENTIFIED BY 'pma'; FLUSH PRIVILEGES;" && \
	mysql -e "CREATE DATABASE IF NOT EXISTS wordpress; GRANT ALL PRIVILEGES ON wordpress.* TO 'pma'@'localhost' IDENTIFIED BY 'pma';FLUSH PRIVILEGES;"


# WORDPRESS CONFIG			
RUN service mysql start
RUN	wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN	chmod +x wp-cli.phar			
RUN	mv wp-cli.phar /usr/local/bin/wp
RUN service mysql start && 	\
	wp core download --allow-root &&	\
	wp config create					\
		--dbname=wordpress				\
		--dbuser=pma					\
		--dbpass=pma					\
		--allow-root &&					\
	wp core install						\
		--allow-root					\
		--url="/"						\
		--title="What up Blood"			\
		--admin_user="admin"			\
		--admin_password="admin"		\
		--admin_email="godsavethequeen@mail.co.uk" &&	\
	mysql -e "USE wordpress; UPDATE wp_options SET option_value='https://localhost/' WHERE option_name='siteurl' OR option_name='home';"

# DON'T YOU REMEMBER THE PISCINE?!
RUN chmod -R 755 *
RUN chown -R www-data:www-data *

# LINKED PORTS TO THE NGINX/DEFAULT FILE
EXPOSE 80 443

# BASHING THE HELL OUT OF ALL THE BELOW
CMD service nginx start && service mysql start && service php7.3-fpm start && bash