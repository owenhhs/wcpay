#!/bin/bash

# WordPress + WooCommerce 开发环境部署脚本
# 适用于 OrbStack Ubuntu 实例

set -e

echo "=========================================="
echo "WordPress + WooCommerce 开发环境部署"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}注意: 建议使用sudo运行此脚本${NC}"
fi

# 更新系统
echo -e "\n${GREEN}[1/10] 更新系统包...${NC}"
apt-get update -qq
apt-get upgrade -y -qq

# 安装必要的软件包
echo -e "\n${GREEN}[2/10] 安装必要的软件包...${NC}"
apt-get install -y \
    software-properties-common \
    curl \
    wget \
    git \
    unzip \
    nano \
    vim \
    ca-certificates \
    gnupg \
    lsb-release

# 添加PHP仓库
echo -e "\n${GREEN}[3/10] 添加PHP 8.1仓库...${NC}"
add-apt-repository -y ppa:ondrej/php
apt-get update -qq

# 安装PHP及相关扩展
echo -e "\n${GREEN}[4/10] 安装PHP 8.1及相关扩展...${NC}"
apt-get install -y \
    php8.1 \
    php8.1-cli \
    php8.1-fpm \
    php8.1-mysql \
    php8.1-xml \
    php8.1-mbstring \
    php8.1-curl \
    php8.1-zip \
    php8.1-gd \
    php8.1-intl \
    php8.1-soap \
    php8.1-bcmath \
    php8.1-opcache

# 安装MySQL
echo -e "\n${GREEN}[5/10] 安装MySQL...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get install -y mysql-server mysql-client

# 配置MySQL
echo -e "\n${GREEN}[6/10] 配置MySQL...${NC}"
if [ ! -f /root/.mysql_configured ]; then
    mysql -e "CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppass123';"
    mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    touch /root/.mysql_configured
    echo -e "${GREEN}MySQL已配置:${NC}"
    echo "  数据库: wordpress"
    echo "  用户: wpuser"
    echo "  密码: wppass123"
fi

# 安装Nginx
echo -e "\n${GREEN}[7/10] 安装Nginx...${NC}"
apt-get install -y nginx

# 下载WordPress
echo -e "\n${GREEN}[8/10] 下载WordPress...${NC}"
WP_DIR="/var/www/wordpress"
if [ ! -d "$WP_DIR" ]; then
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    mv wordpress $WP_DIR
    chown -R www-data:www-data $WP_DIR
    chmod -R 755 $WP_DIR
    rm latest.tar.gz
    echo -e "${GREEN}WordPress已下载到: $WP_DIR${NC}"
else
    echo -e "${YELLOW}WordPress目录已存在，跳过下载${NC}"
fi

# 配置WordPress
echo -e "\n${GREEN}[9/10] 配置WordPress...${NC}"
if [ ! -f "$WP_DIR/wp-config.php" ]; then
    cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php
    
    # 生成密钥
    curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/wp-keys.txt
    
    # 更新配置文件
    sed -i "s/database_name_here/wordpress/g" $WP_DIR/wp-config.php
    sed -i "s/username_here/wpuser/g" $WP_DIR/wp-config.php
    sed -i "s/password_here/wppass123/g" $WP_DIR/wp-config.php
    sed -i "s/localhost/localhost/g" $WP_DIR/wp-config.php
    
    # 添加调试模式
    sed -i "/That's all, stop editing!/i define('WP_DEBUG', true);" $WP_DIR/wp-config.php
    sed -i "/That's all, stop editing!/i define('WP_DEBUG_LOG', true);" $WP_DIR/wp-config.php
    sed -i "/That's all, stop editing!/i define('WP_DEBUG_DISPLAY', false);" $WP_DIR/wp-config.php
    sed -i "/That's all, stop editing!/i @ini_set('display_errors', 0);" $WP_DIR/wp-config.php
    
    echo -e "${GREEN}WordPress配置文件已创建${NC}"
else
    echo -e "${YELLOW}WordPress配置文件已存在${NC}"
fi

# 配置Nginx
echo -e "\n${GREEN}[10/10] 配置Nginx...${NC}"
cat > /etc/nginx/sites-available/wordpress << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name localhost;
    root /var/www/wordpress;
    index index.php index.html index.htm;

    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        log_not_found off;
        access_log off;
        allow all;
    }
}
EOF

# 启用站点
ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 测试Nginx配置
nginx -t

# 启动服务
echo -e "\n${GREEN}启动服务...${NC}"
systemctl enable nginx mysql php8.1-fpm
systemctl restart nginx mysql php8.1-fpm

# 安装WP-CLI
echo -e "\n${GREEN}安装WP-CLI...${NC}"
if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    echo -e "${GREEN}WP-CLI已安装${NC}"
else
    echo -e "${YELLOW}WP-CLI已存在${NC}"
fi

echo -e "\n${GREEN}=========================================="
echo "部署完成！"
echo "==========================================${NC}"
echo ""
echo "WordPress信息:"
echo "  目录: $WP_DIR"
echo "  URL: http://localhost"
echo ""
echo "数据库信息:"
echo "  数据库: wordpress"
echo "  用户: wpuser"
echo "  密码: wppass123"
echo ""
echo "下一步:"
echo "  1. 访问 http://localhost 完成WordPress安装"
echo "  2. 运行: bash scripts/install-woocommerce.sh"
echo "  3. 运行: bash scripts/deploy-plugin.sh"
echo ""

