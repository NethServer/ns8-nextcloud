FROM docker.io/library/nextcloud:33.0.10-fpm-alpine

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
    docker-php-ext-install bz2; \
    pecl install imap; \
    docker-php-ext-enable imap; \
    \
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

COPY supervisord.conf /
COPY ns.config.php /usr/src/nextcloud/config/

# Mitigate CVE-2026-109618 / CVE-2026-109619, Nextcloud does not use session upload progress
RUN echo 'session.upload_progress.enabled = Off' > /usr/local/etc/php/conf.d/zz-session-upload-progress.ini

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
