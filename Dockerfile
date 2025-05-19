FROM php:8.2-apache

# تثبيت dependencies النظام وملحقات PHP
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
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    intl \
    zip \
    gd \
    calendar \
    && pecl install redis && docker-php-ext-enable redis

# تفعيل Apache modules
RUN a2enmod rewrite headers

# تعيين مجلد العمل
WORKDIR /var/www/html

# نسخ ملفات المشروع
COPY . .

# تثبيت Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# إنشاء مجلدات التخزين وتعيين الصلاحيات
RUN mkdir -p \
    storage/framework/{cache,sessions,views} \
    storage/logs \
    bootstrap/cache \
    && chown -R www-data:www-data \
    storage \
    bootstrap/cache \
    && chmod -R 775 \
    storage \
    bootstrap/cache

# تثبيت dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction

# إنشاء ملف .env إذا لم يكن موجوداً
RUN if [ ! -f .env ]; then \
    cp .env.example .env \
    && php artisan key:generate; \
    fi

# تهيئة التطبيق
RUN php artisan storage:link \
    && php artisan optimize:clear \
    && php artisan config:cache \
    && php artisan route:cache \
    && php artisan view:cache

# تعيين DocumentRoot لـ Apache
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# تعيين الصلاحيات النهائية
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage

EXPOSE 80

# تشغيل Apache بدلاً من artisan serve (أفضل لـ Render)
CMD ["apache2-foreground"]