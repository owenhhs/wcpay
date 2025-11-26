#!/bin/bash

# 一键安装所有开发环境组件
# 在Ubuntu环境中运行此脚本

set -e

echo "=========================================="
echo "开始安装开发环境"
echo "=========================================="
echo ""
echo "将安装以下组件："
echo "  ✓ PHP 8.1 及相关扩展"
echo "  ✓ MySQL 数据库"
echo "  ✓ Nginx Web服务器"
echo "  ✓ WordPress"
echo "  ✓ WP-CLI"
echo "  ✓ WooCommerce"
echo "  ✓ 支付插件"
echo ""
echo "预计需要 10-15 分钟"
echo ""
read -p "是否继续？(y/n): " proceed

if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
    echo "已取消"
    exit 0
fi

# 检查是否为root或有sudo权限
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then 
    echo ""
    echo "此脚本需要sudo权限"
    echo "请确保可以运行sudo命令"
    read -p "是否继续？(y/n): " continue_as_root
    if [ "$continue_as_root" != "y" ] && [ "$continue_as_root" != "Y" ]; then
        exit 1
    fi
fi

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

echo ""
echo "=========================================="
echo "[1/8] 更新系统包"
echo "=========================================="
$SUDO apt-get update -qq
echo "✓ 系统包已更新"
echo ""

echo "=========================================="
echo "[2/8] 安装基础工具"
echo "=========================================="
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
    lsb-release >/dev/null 2>&1
echo "✓ 基础工具已安装"
echo ""

echo "=========================================="
echo "[3/8] 添加PHP仓库并安装PHP 8.1"
echo "=========================================="
$SUDO add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1
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
echo "✓ PHP 8.1 已安装"
php -v | head -1
echo ""

echo "=========================================="
echo "[4/8] 安装MySQL"
echo "=========================================="
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get install -y -qq mysql-server mysql-client >/dev/null 2>&1

# 配置MySQL
if [ ! -f /root/.mysql_wp_configured ]; then
    echo "  配置MySQL数据库..."
    $SUDO mysql -e "CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    $SUDO mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppass123';" 2>/dev/null || true
    $SUDO mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';" 2>/dev/null || true
    $SUDO mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    $SUDO touch /root/.mysql_wp_configured
    echo "  ✓ 数据库已配置"
fi

# 启动MySQL服务
$SUDO systemctl start mysql >/dev/null 2>&1 || true
$SUDO systemctl enable mysql >/dev/null 2>&1 || true

echo "✓ MySQL 已安装并配置"
echo "  数据库: wordpress"
echo "  用户: wpuser"
echo "  密码: wppass123"
echo ""

echo "=========================================="
echo "[5/8] 安装Nginx"
echo "=========================================="
$SUDO apt-get install -y -qq nginx >/dev/null 2>&1
echo "✓ Nginx 已安装"
echo ""

echo "=========================================="
echo "[6/8] 下载并配置WordPress"
echo "=========================================="
WP_DIR="/var/www/wordpress"

if [ ! -d "$WP_DIR" ]; then
    echo "  下载WordPress..."
    cd /tmp
    wget -q https://wordpress.org/latest.tar.gz || \
        wget -q https://cn.wordpress.org/latest-zh_CN.tar.gz -O latest.tar.gz || {
        echo "  ✗ 下载WordPress失败，请检查网络"
        exit 1
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
    echo "  配置WordPress..."
    $SUDO cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php
    
    # 更新数据库配置
    $SUDO sed -i "s/database_name_here/wordpress/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/username_here/wpuser/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/password_here/wppass123/g" $WP_DIR/wp-config.php
    
    # 启用调试
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_LOG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_DISPLAY', false);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i @ini_set('display_errors', 0);" $WP_DIR/wp-config.php
    
    echo "  ✓ WordPress配置完成"
fi

echo "✓ WordPress已准备就绪"
echo ""

echo "=========================================="
echo "[7/8] 配置Nginx"
echo "=========================================="
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

$SUDO ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
$SUDO rm -f /etc/nginx/sites-enabled/default

# 测试Nginx配置
$SUDO nginx -t >/dev/null 2>&1 || echo "  ⚠ Nginx配置测试失败"

echo "✓ Nginx已配置"
echo ""

echo "=========================================="
echo "[8/8] 安装WP-CLI和启动服务"
echo "=========================================="

# 安装WP-CLI
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

# 启动所有服务
echo "  启动服务..."
$SUDO systemctl enable nginx mysql php8.1-fpm >/dev/null 2>&1
$SUDO systemctl restart nginx mysql php8.1-fpm >/dev/null 2>&1

echo "✓ 服务已启动"
echo ""

# 获取IP地址
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
echo "下一步："
echo "  1. 访问 http://$IP 完成WordPress安装"
echo "  2. 运行: sudo bash scripts/install-woocommerce.sh"
echo "  3. 运行: sudo bash scripts/deploy-plugin.sh"
echo ""
echo "或者运行完整安装："
echo "  cd ~/wcpay && sudo bash scripts/install-all-complete.sh"
echo ""

