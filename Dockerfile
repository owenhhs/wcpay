# WordPress开发环境Dockerfile
# 用于构建包含WooCommerce和支付插件的WordPress镜像

FROM wordpress:latest

# 安装必要的PHP扩展和工具
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 安装WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# 设置工作目录
WORKDIR /var/www/html

# 复制自定义PHP配置
COPY docker/php.ini /usr/local/etc/php/conf.d/custom.ini

# 设置权限
RUN chown -R www-data:www-data /var/www/html

# 暴露端口
EXPOSE 80

