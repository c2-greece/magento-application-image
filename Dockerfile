FROM php:7.4-fpm-buster

MAINTAINER Cloud Concept S.A. <support@c2.gr>

RUN apt-get update && apt-get install -y \
    git \
    zip \
    curl \
    sudo \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libxml2-dev \
    libzip-dev \
    libtidy-dev \
    libxslt-dev \
    libgearman-dev \
    libcurl4-openssl-dev \
    libwebp-dev \    
    g++ libffi6 libffi-dev\
    wget \
    gnupg \
    gnupg2 \
    gnupg1 \
    nano \
    iputils-ping \
    mtr net-tools  \
    htop  \
    nginx  \
    openssl  \
    dnsutils  \
    sshfs  \
    rsyslog

WORKDIR /
 
ENV phpinipath=/usr/local/etc/php/php.ini

# Install additional PHP modules
RUN pecl install apcu-5.1.20 && docker-php-ext-enable apcu
RUN echo "extension=apcu.so" >> $phpinipath
RUN echo "apc.enable_cli=1" >> $phpinipath
RUN echo "apc.enable=1" >> $phpinipath
RUN docker-php-ext-install mysqli pdo pdo_mysql  soap exif intl opcache zip tidy gettext  bcmath bz2 calendar ffi simplexml xsl sockets
RUN pecl install -o -f memcache && pecl install -o -f redis && rm -rf /tmp/pear &&  docker-php-ext-enable memcache &&  docker-php-ext-enable redis
RUN docker-php-ext-configure gd --with-freetype --with-webp --with-jpeg &&  docker-php-ext-install gd
RUN echo "memcache.hash_strategy=consistent" >> /usr/local/etc/php/conf.d/docker-php-ext-memcache.ini

RUN echo "aaa"
# PHP config
RUN cp /usr/local/etc/php/php.ini-production $phpinipath
# COPY ./devops/configs/php.cms.ini /usr/local/etc/php/php.ini-cms
RUN sed -i -e "s/;\?daemonize\s*=\s*yes/daemonize = no/g"  /usr/local/etc/php-fpm.conf
RUN sed -i -e "s/;\?date.timezone\s*=\s*.*/date.timezone = Europe\/Athens/g" $phpinipath
RUN sed -i -e "s/upload_max_filesize\s*=\s*.*/upload_max_filesize = 100M/g" $phpinipath
RUN sed -i -e "s/post_max_size\s*=\s*.*/post_max_size = 100M/g" $phpinipath
RUN sed -i '/listen =.*/c\listen = \/var\/run\/php7.4-fpm.sock' /usr/local/etc/php-fpm.d/zz-docker.conf
RUN sed -i '/;listen.owner = www-data/c\listen.owner = www-data' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i '/;listen.group = www-data/c\listen.group = www-data' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i '/;listen.mode =.*/c\listen.mode = 0660' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i -e "s/;\?memory_limit\s*=\s*.*/memory_limit = 1024M/g" $phpinipath
RUN sed -i -e "s/;\?max_execution_time\s*=\s*.*/max_execution_time = 180/g" $phpinipath

#RUN sed -i -e "s/;\?session.save_handler\s*=\s*.*/session.save_handler = memcached/g" $phpinipath
#RUN sed -i -e "s/;\?session.save_path\s*=\s*.*/session.save_path = 10.110.18.101:31211,10.110.18.102:31211/g" $phpinipath
RUN sed -i '/pm.max_children/c\pm.max_children = 50' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i '/pm.start_servers/c\pm.start_servers = 25' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i '/pm.min_spare_servers/c\pm.min_spare_servers = 15' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i '/pm.max_spare_servers/c\pm.max_spare_servers = 50' /usr/local/etc/php-fpm.d/www.conf
# Cleanup comments
RUN sed -i -r '/^[\s\t]*[#;]/d' $phpinipath
RUN sed -i -r '/^\s*$/d' $phpinipath
RUN sed -i -r '/^[\s\t]*[#;]/d' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i -r '/^\s*$/d' /usr/local/etc/php-fpm.d/www.conf

#Cleanup image
RUN rm -rf /var/lib/{apt,dpkg,cache,log}/*

#setup Nginx
RUN rm -fr /etc/nginx/sites-available /etc/nginx/sites-enabled
COPY ./configs/nginx.conf /etc/nginx/nginx.conf
RUN nginx -t

# Add fresh code
RUN mkdir -p /var/www/html/ && rm -rf /var/www/html/*

WORKDIR /var/www/html/

EXPOSE 80


