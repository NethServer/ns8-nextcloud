FROM docker.io/library/nextcloud:_NC_VERSION_-fpm-alpine

RUN set -ex; \
    \
    apk add --no-cache \
        ffmpeg \
        imagemagick \
        procps \
        samba-client \
        supervisor \
#       libreoffice \
    ;

RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        imap-dev \
        krb5-dev \
        openssl-dev \
        samba-dev \
        bzip2-dev \
    ; \
    \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    docker-php-ext-install \
        bz2 \
        imap \
    ; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --virtual .nextcloud-phpext-rundeps $runDeps; \
    apk del .build-deps

RUN mkdir -p \
    /var/log/supervisord \
    /var/run/supervisord \
;
# we want to remove the php notice in error reporting in log, sed is doing weird things
RUN sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/#error_reporting_added_at_the_end_of_file/' /usr/local/etc/php/php.ini-production && \
    echo 'error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE' >> /usr/local/etc/php/php.ini-production

COPY supervisord.conf /
COPY ns.config.php /usr/src/nextcloud/config/

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
