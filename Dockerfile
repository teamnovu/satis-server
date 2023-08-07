ARG WEBHOOK_VERSION
FROM alpine:3.17 as ts
ENV TS_VERSION 1.0

WORKDIR /tmp
RUN apk add -U wget make gcc linux-headers g++ && \
    wget http://vicerveza.homeunix.net/~viric/soft/ts/ts-${TS_VERSION}.tar.gz && \
    tar zxvf ts-${TS_VERSION}.tar.gz && \
    cd ts-${TS_VERSION}/ && \
    make && \
    mv ts /ts

FROM almir/webhook:${WEBHOOK_VERSION} AS webhook

FROM composer/satis AS satis

ARG SATIS_SERVER_VERSION
ENV SATIS_SERVER_VERSION ${SATIS_SERVER_VERSION:-dev-main}

LABEL maintainer="Łukasz Lach <llach@llach.pl>" \
    org.label-schema.name="satis-server" \
    org.label-schema.description="Satis Server" \
    org.label-schema.usage="https://github.com/lukaszlach/satis-server/blob/master/README.md" \
    org.label-schema.url="https://github.com/lukaszlach/satis-server" \
    org.label-schema.vcs-url="https://github.com/lukaszlach/satis-server" \
    org.label-schema.version="${SATIS_SERVER_VERSION:-dev-main}" \
    org.label-schema.schema-version="1.1"
WORKDIR /satis-server

RUN apk update && \
    apk -U add jq nginx tini php82 php82-fpm php82-curl supervisor && \
    rm -rf /var/cache/apk/* /etc/nginx/conf.d/* && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    mkdir -p /root/.ssh/satis-server /etc/webhook && \
    # use socket for php-fpm
    sed -i 's/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm\/php-fpm.sock/g' /etc/php82/php-fpm.d/www.conf && \
    mkdir -p /var/run/php-fpm && \
    # Change user and group for PHP-FPM
    sed -i 's/;listen.owner = nobody/listen.owner = nginx/g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/;listen.group = nobody/listen.group = nginx/g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/;listen.mode = 0660/listen.mode = 0660/g' /etc/php82/php-fpm.d/www.conf && \
    chown -R nginx:nginx /var/run/php-fpm && chmod 755 /var/run/php-fpm && \
    sed -i 's/user = nobody/user = nginx/g' /etc/php82/php-fpm.d/www.conf && \
    sed -i 's/group = nobody/group = nginx/g' /etc/php82/php-fpm.d/www.conf && \
    # Fix error logging
    sed -i 's/;error_log = syslog/error_log = \/dev\/stderr/g' /etc/php82/php.ini && \
    echo "catch_workers_output = yes" >> /etc/php82/php-fpm.d/www.conf && \
    echo "decorate_workers_output = no" >> /etc/php82/php-fpm.d/www.conf && \
    # do not clear env variables
    echo "clear_env = no" >> /etc/php82/php-fpm.d/www.conf  && \
    # Dont expose PHP version
    echo "expose_php=off" >> /etc/php82/conf.d/99-overrides.ini && \
    # Check syntax for nginx
    nginx -t

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    chmod +x /usr/local/bin/composer

ADD . .
ADD src/auth.php /var/www/html
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --from=webhook /usr/local/bin/webhook /satis-server/bin/webhook
COPY --from=ts /ts /satis-server/bin/ts

RUN ln -s /satis-server/webhook/hooks.json /etc/webhook/hooks.json && \
    ln -s /satis-server/bin/webhook /usr/local/bin/webhook && \
    ln -s /satis-server/bin/satis-server.sh /usr/local/bin/satis-server && \
    ln -s /satis-server/bin/satis-build.sh /usr/local/bin/satis-build && \
    ln -s /satis-server/bin/satis-build-all.sh /usr/local/bin/satis-build-all && \
    ln -s /satis-server/bin/satis-add.sh /usr/local/bin/satis-add && \
    ln -s /satis-server/bin/satis-remove.sh /usr/local/bin/satis-remove && \
    ln -s /satis-server/bin/satis-list.sh /usr/local/bin/satis-list && \
    ln -s /satis-server/bin/satis-show.sh /usr/local/bin/satis-show && \
    ln -s /satis-server/bin/satis-dump.sh /usr/local/bin/satis-dump && \
    ln -s /satis-server/bin/scw-version.sh /usr/local/bin/satis-server-version && \
    ln -s /satis-server/bin/scw-help.sh /usr/local/bin/satis-server-help && \
    ln -s /satis/bin/satis /usr/local/bin/satis && \
    chmod +x /satis-server/bin/*

EXPOSE 80/tcp 443/tcp
VOLUME /etc/satis /etc/satis-server /var/satis-server
HEALTHCHECK --interval=1m --timeout=10s \
    CMD ( curl -f http://localhost:80/ping && curl -f http://localhost:9000/api/ping ) || exit 1

# ENTRYPOINT ["/satis-server/bin/docker-entrypoint.sh"]
# CMD ["satis-server"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
