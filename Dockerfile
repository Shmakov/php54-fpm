FROM php:5.4.45-fpm

# libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng12-dev - for gd
# zlib1g-dev libicu-dev - for intl
# libmagickwand-dev - for imagick
# libmemcached-dev - for memcached

#Issue with fetching http://deb.debian.org/debian/dists/jessie-updates/InRelease with docker
#https://superuser.com/questions/1423486/issue-with-fetching-http-deb-debian-org-debian-dists-jessie-updates-inrelease
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

RUN apt-get update && \
    buildDependencies=" \
        git \
        zlib1g-dev \
        libmemcached-dev \
    " && \
    doNotUninstall=" \
        libmemcached11 \
        libmemcachedutil2 \
    " && \
    apt-get install -y $buildDependencies --no-install-recommends && \
    rm -r /var/lib/apt/lists/* && \
    apt-mark manual $doNotUninstall && \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDependencies

RUN apt-get update && \
    mainDependencies=" \
        git \
        zip \
        zlib1g-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
        libicu-dev \
        libmagickwand-dev \
    " && \
    apt-get install -y $mainDependencies \
    --no-install-recommends

RUN docker-php-ext-configure intl && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ && \
    docker-php-ext-install pdo_mysql json mbstring exif mcrypt mysql mysqli intl gd zip && \
# imagick
    pecl install imagick && \
    docker-php-ext-enable imagick && \
    rm -r /tmp/pear/*

# imagemagick, pdftk, ghostscript, unzip, update CA certificates
RUN apt-get -y install imagemagick pdftk=2.02-2 ghostscript ca-certificates unzip && \
    update-ca-certificates

# imap
RUN apt-get update && apt-get install -y libc-client-dev libkrb5-dev && rm -r /var/lib/apt/lists/*
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

ENV VERSION_PRESTISSIMO_PLUGIN=^0.3.0 \
    COMPOSER_ALLOW_SUPERUSER=1
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && composer global require --optimize-autoloader \
        "hirak/prestissimo:${VERSION_PRESTISSIMO_PLUGIN}" \
    && composer global dumpautoload --optimize

# memcache
RUN yes '' | pecl install memcache && \
    docker-php-ext-enable memcache

# install mhsendmail
RUN curl -Lo /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 && \
    chmod +x /usr/local/bin/mhsendmail

# xdebug
RUN pecl install xdebug-2.4.1

# ZendOpcache
RUN pecl install zendopcache-7.0.5