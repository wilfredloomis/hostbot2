FROM php:8.3-apache

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl fuse3 libcurl4-openssl-dev mount \
    && docker-php-ext-install curl \
    && version="v1.2.1" \
    && curl -fsSL "https://github.com/tigrisdata/tigrisfs/releases/download/${version}/tigrisfs_${version#v}_linux_amd64.tar.gz" -o /tmp/tigrisfs.tar.gz \
    && tar -xzf /tmp/tigrisfs.tar.gz -C /usr/local/bin/ \
    && chmod +x /usr/local/bin/tigrisfs \
    && rm -rf /var/lib/apt/lists/* /tmp/tigrisfs.tar.gz \
    && sed -ri 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
    && sed -ri 's/<VirtualHost \*:80>/<VirtualHost *:8080>/' /etc/apache2/sites-available/000-default.conf \
    && printf 'upload_max_filesize=10M\npost_max_size=11M\nmax_execution_time=30\ndisplay_errors=Off\n' > /usr/local/etc/php/conf.d/bot-host.ini

COPY index.php upload.php webhook.php /var/www/html/
COPY start-container.sh /usr/local/bin/start-container

RUN chmod +x /usr/local/bin/start-container \
    && chown -R www-data:www-data /var/www/html

EXPOSE 8080
CMD ["/usr/local/bin/start-container"]
