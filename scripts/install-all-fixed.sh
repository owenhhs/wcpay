#!/bin/bash

# 一键安装所有开发环境组件 - 修复版
# 支持Ubuntu 25.10

set -e

echo "=========================================="
echo "开始安装开发环境"
echo "=========================================="
echo ""

# 检查是否为root或有sudo权限
SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

echo "[1/8] 更新系统包..."
$SUDO apt-get update -qq
echo "✓ 系统包已更新"
echo ""

echo "[2/8] 安装基础工具..."
$SUDO apt-get install -y -qq \
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
    lsb-release \
    bc >/dev/null 2>&1
echo "✓ 基础工具已安装"
echo ""

echo "[3/8] 安装PHP..."
# 检测Ubuntu版本
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")
echo "检测到Ubuntu版本: $UBUNTU_VERSION"

# 检查系统是否有PHP可用
if apt-cache search "^php8\.[0-9]" 2>/dev/null | head -1 | grep -q php; then
    echo "使用系统默认PHP仓库..."
    $SUDO apt-get update -qq
    
    # 检测可用的PHP版本
    PHP_VER=""
    for ver in 8.4 8.3 8.2 8.1 8.0; do
        if apt-cache search "^php${ver}" 2>/dev/null | head -1 | grep -q "php${ver}"; then
            PHP_VER="$ver"
            echo "找到PHP版本: $PHP_VER"
            break
        fi
    done
    
    if [ -z "$PHP_VER" ]; then
        # 使用通用的php包
        echo "安装系统默认PHP..."
        $SUDO apt-get install -y -qq \
            php \
            php-cli \
            php-fpm \
            php-mysql \
            php-xml \
            php-mbstring \
            php-curl \
            php-zip \
            php-gd \
            php-intl \
            php-opcache >/dev/null 2>&1
        PHP_VER="default"
    else
        echo "安装PHP $PHP_VER..."
        $SUDO apt-get install -y -qq \
            php${PHP_VER} \
            php${PHP_VER}-cli \
            php${PHP_VER}-fpm \
            php${PHP_VER}-mysql \
            php${PHP_VER}-xml \
            php${PHP_VER}-mbstring \
            php${PHP_VER}-curl \
            php${PHP_VER}-zip \
            php${PHP_VER}-gd \
            php${PHP_VER}-intl \
            php${PHP_VER}-opcache >/dev/null 2>&1
    fi
else
    # 尝试使用PPA（仅对旧版本）
    echo "尝试添加PHP PPA仓库..."
    $SUDO add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1 || {
        echo "PPA添加失败，使用系统默认PHP..."
        $SUDO apt-get install -y -qq \
            php \
            php-cli \
            php-fpm \
            php-mysql \
            php-xml \
            php-mbstring \
            php-curl \
            php-zip \
            php-gd \
            php-intl \
            php-opcache >/dev/null 2>&1
        PHP_VER="default"
    }
    
    if [ "$PHP_VER" != "default" ]; then
        $SUDO apt-get update -qq
        $SUDO apt-get install -y -qq \
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
            php8.1-opcache >/dev/null 2>&1
        PHP_VER="8.1"
    fi
fi

echo "✓ PHP已安装"
php -v | head -1

# 检测PHP-FPM服务名和socket路径
PHP_FPM_SERVICE="php-fpm"
PHP_FPM_SOCK="unix:/var/run/php/php-fpm.sock"

if systemctl list-unit-files | grep -q "php8.3-fpm"; then
    PHP_FPM_SERVICE="php8.3-fpm"
    PHP_FPM_SOCK="unix:/var/run/php/php8.3-fpm.sock"
elif systemctl list-unit-files | grep -q "php8.2-fpm"; then
    PHP_FPM_SERVICE="php8.2-fpm"
    PHP_FPM_SOCK="unix:/var/run/php/php8.2-fpm.sock"
elif systemctl list-unit-files | grep -q "php8.1-fpm"; then
    PHP_FPM_SERVICE="php8.1-fpm"
    PHP_FPM_SOCK="unix:/var/run/php/php8.1-fpm.sock"
fi

echo ""
echo "[4/8] 安装MySQL..."
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get install -y -qq mysql-server mysql-client >/dev/null 2>&1

if [ ! -f /root/.mysql_wp_configured ]; then
    echo "  配置MySQL数据库..."
    $SUDO mysql -e "CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    $SUDO mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppass123';" 2>/dev/null || true
    $SUDO mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';" 2>/dev/null || true
    $SUDO mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    $SUDO touch /root/.mysql_wp_configured
    echo "  ✓ 数据库已配置"
fi

$SUDO systemctl start mysql >/dev/null 2>&1 || true
$SUDO systemctl enable mysql >/dev/null 2>&1 || true

echo "✓ MySQL已安装"
echo ""

echo "[5/8] 安装Nginx..."
$SUDO apt-get install -y -qq nginx >/dev/null 2>&1
echo "✓ Nginx已安装"
echo ""

echo "[6/8] 下载并配置WordPress..."
WP_DIR="/var/www/wordpress"

if [ ! -d "$WP_DIR" ]; then
    echo "  下载WordPress..."
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz || \
        wget -q https://cn.wordpress.org/latest-zh_CN.tar.gz -O latest.tar.gz || {
        echo "  ✗ 下载失败，请检查网络"
        exit 1
    }
    
    tar -xzf latest.tar.gz
    $SUDO mv wordpress $WP_DIR
    $SUDO chown -R www-data:www-data $WP_DIR
    $SUDO chmod -R 755 $WP_DIR
    rm -f latest.tar.gz
    echo "  ✓ WordPress已下载"
fi

if [ ! -f "$WP_DIR/wp-config.php" ]; then
    echo "  配置WordPress..."
    $SUDO cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php
    
    $SUDO sed -i "s/database_name_here/wordpress/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/username_here/wpuser/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/password_here/wppass123/g" $WP_DIR/wp-config.php
    
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_LOG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_DISPLAY', false);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i @ini_set('display_errors', 0);" $WP_DIR/wp-config.php
    
    echo "  ✓ WordPress配置完成"
fi

echo "✓ WordPress已准备就绪"
echo ""

echo "[7/8] 配置Nginx..."
# 使用检测到的PHP-FPM socket
$SUDO tee /etc/nginx/sites-available/wordpress > /dev/null << EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /var/www/wordpress;
    index index.php index.html index.htm;

    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass $PHP_FPM_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

$SUDO ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
$SUDO rm -f /etc/nginx/sites-enabled/default

$SUDO nginx -t >/dev/null 2>&1 || echo "  ⚠ Nginx配置测试失败"

echo "✓ Nginx已配置"
echo ""

echo "[8/8] 安装WP-CLI和启动服务..."
if [ ! -f /usr/local/bin/wp ]; then
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>/dev/null || echo "  ⚠ 无法下载WP-CLI"
    if [ -f wp-cli.phar ]; then
        $SUDO chmod +x wp-cli.phar
        $SUDO mv wp-cli.phar /usr/local/bin/wp
        echo "  ✓ WP-CLI已安装"
    fi
fi

echo "  启动服务..."
$SUDO systemctl enable nginx mysql $PHP_FPM_SERVICE >/dev/null 2>&1
$SUDO systemctl restart nginx mysql $PHP_FPM_SERVICE >/dev/null 2>&1

echo "✓ 服务已启动"
echo ""

IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""
echo "WordPress信息："
echo "  目录: $WP_DIR"
echo "  URL: http://$IP"
echo ""
echo "数据库信息："
echo "  数据库: wordpress"
echo "  用户: wpuser"
echo "  密码: wppass123"
echo ""
echo "PHP版本: $(php -v | head -1)"
echo "PHP-FPM服务: $PHP_FPM_SERVICE"
echo ""
echo "下一步："
echo "  1. 访问 http://$IP 完成WordPress安装"
echo "  2. 运行: sudo bash scripts/install-woocommerce.sh"
echo "  3. 运行: sudo bash scripts/deploy-plugin.sh"
echo ""

