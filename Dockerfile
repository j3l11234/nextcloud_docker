FROM nextcloud:21.0.3-fpm-alpine

RUN set -ex; \
    \
    apk add --no-cache \
        ffmpeg \
        imagemagick \
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

# RUN apk add --no-cache procps samba-client

RUN echo -e "\$AUTOCONFIG['check_data_directory_permissions'] = false;" >> /usr/src/nextcloud/config/autoconfig.php
RUN sed -i 's/pm.max_children = .*/pm.max_children = 10/' /usr/local/etc/php-fpm.d/www.conf

COPY libsmbclient-4.14.5-r0.apk /tmp
RUN set -ex; \
    \
    apk add --no-cache --allow-untrusted  /tmp/libsmbclient-4.14.5-r0.apk \
    rm /tmp/libsmbclient-4.14.5-r0.apk