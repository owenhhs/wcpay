#!/bin/bash

# OrbStack Ubuntu环境快速设置脚本
# 在OrbStack的Ubuntu实例中运行此脚本

set -e

echo "=========================================="
echo "OrbStack Ubuntu环境设置"
echo "=========================================="

# 检查是否为root或有sudo权限
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then 
    echo "此脚本需要sudo权限"
    exit 1
fi

# 使用sudo前缀
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# 更新系统
echo ""
echo "[1/8] 更新系统..."
$SUDO apt-get update -qq
$SUDO apt-get upgrade -y -qq

# 安装基础工具
echo ""
echo "[2/8] 安装基础工具..."
$SUDO apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    vim \
    nano \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# 添加PHP仓库
echo ""
echo "[3/8] 添加PHP 8.1仓库..."
$SUDO add-apt-repository -y ppa:ondrej/php
$SUDO apt-get update -qq

# 安装PHP
echo ""
echo "[4/8] 安装PHP 8.1..."
$SUDO apt-get install -y \
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
    php8.1-opcache

# 安装MySQL
echo ""
echo "[5/8] 安装MySQL..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get install -y mysql-server mysql-client

# 配置MySQL
echo ""
echo "[6/8] 配置MySQL..."
if [ ! -f /root/.mysql_wp_configured ]; then
    $SUDO mysql -e "CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    $SUDO mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppass123';" 2>/dev/null || true
    $SUDO mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';" 2>/dev/null || true
    $SUDO mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    $SUDO touch /root/.mysql_wp_configured
    echo "  ✓ MySQL数据库已配置"
    echo "    数据库: wordpress"
    echo "    用户: wpuser"
    echo "    密码: wppass123"
fi

# 安装Nginx
echo ""
echo "[7/8] 安装Nginx..."
$SUDO apt-get install -y nginx

# 下载WordPress
echo ""
echo "[8/8] 下载并配置WordPress..."
WP_DIR="/var/www/wordpress"
if [ ! -d "$WP_DIR" ]; then
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz || {
        echo "下载WordPress失败，尝试使用镜像源..."
        wget -q https://cn.wordpress.org/latest-zh_CN.tar.gz -O latest.tar.gz || {
            echo "无法下载WordPress，请手动下载"
            exit 1
        }
    }
    tar -xzf latest.tar.gz
    $SUDO mv wordpress $WP_DIR
    $SUDO chown -R www-data:www-data $WP_DIR
    $SUDO chmod -R 755 $WP_DIR
    rm -f latest.tar.gz
    echo "  ✓ WordPress已下载"
fi

# 配置WordPress
if [ ! -f "$WP_DIR/wp-config.php" ]; then
    $SUDO cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php
    
    # 更新数据库配置
    $SUDO sed -i "s/database_name_here/wordpress/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/username_here/wpuser/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/password_here/wppass123/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/localhost/localhost/g" $WP_DIR/wp-config.php
    
    # 启用调试
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_LOG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_DISPLAY', false);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i @ini_set('display_errors', 0);" $WP_DIR/wp-config.php
    
    echo "  ✓ WordPress配置完成"
fi

# 配置Nginx
echo ""
echo "配置Nginx..."
$SUDO tee /etc/nginx/sites-available/wordpress > /dev/null << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;
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
}
EOF

# 启用站点
$SUDO ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
$SUDO rm -f /etc/nginx/sites-enabled/default

# 测试Nginx配置
$SUDO nginx -t

# 安装WP-CLI
echo ""
echo "安装WP-CLI..."
if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>/dev/null || {
        echo "  ⚠ 无法下载WP-CLI，跳过"
    }
    if [ -f wp-cli.phar ]; then
        $SUDO chmod +x wp-cli.phar
        $SUDO mv wp-cli.phar /usr/local/bin/wp
        echo "  ✓ WP-CLI已安装"
    fi
fi

# 启动服务
echo ""
echo "启动服务..."
$SUDO systemctl enable nginx mysql php8.1-fpm
$SUDO systemctl restart nginx mysql php8.1-fpm

# 获取IP地址
IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================="
echo "环境设置完成！"
echo "=========================================="
echo ""
echo "WordPress信息:"
echo "  目录: $WP_DIR"
echo "  URL: http://$IP 或 http://localhost"
echo ""
echo "数据库信息:"
echo "  数据库: wordpress"
echo "  用户: wpuser"
echo "  密码: wppass123"
echo ""
echo "下一步:"
echo "  1. 访问 http://$IP 完成WordPress安装"
echo "  2. 运行: bash install-woocommerce.sh"
echo "  3. 运行: bash deploy-plugin.sh"
echo ""

