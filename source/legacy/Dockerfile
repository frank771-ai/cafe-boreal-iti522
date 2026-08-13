FROM php:8.3-apache
RUN apt-get update && apt-get install -y --no-install-recommends sqlite3 libsqlite3-dev \
 && docker-php-ext-install pdo_sqlite \
 && rm -rf /var/lib/apt/lists/* \
 && a2enmod rewrite headers
COPY public/ /var/www/html/
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html
EXPOSE 80
