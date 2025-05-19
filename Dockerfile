FROM php:8.2-apache

# Install system dependencies & PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libgd-dev \
    curl \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    intl \
    zip \
    gd \
    calendar

# Enable Apache Rewrite Module
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy project files
COPY . .

# Install Composer (latest stable)
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# ✅ Fix cache error - Create cache path manually
RUN mkdir -p bootstrap/cache && \
    mkdir -p storage/framework/{cache,sessions,views} && \
    mkdir -p storage/logs && \
    chown -R www-data:www-data bootstrap/cache storage && \
    chmod -R 755 bootstrap/cache storage

# Install Laravel dependencies (optimized)
RUN composer install --optimize-autoloader --no-dev --no-plugins

# Permissions
RUN chown -R www-data:www-data /var/www/html

# Expose port
EXPOSE 80

# Start Laravel with artisan
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=80"]
