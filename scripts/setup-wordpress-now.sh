#!/bin/bash

# 立即设置WordPress - 完整流程

set -e

echo "=========================================="
echo "设置WordPress"
echo "=========================================="
echo ""

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# 步骤1: 创建目录并下载WordPress
echo "[1/5] 下载WordPress..."
WP_DIR="/var/www/wordpress"

if [ ! -d "$WP_DIR" ]; then
    echo "  创建目录..."
    $SUDO mkdir -p /var/www
    $SUDO chown -R $USER:$USER /var/www 2>/dev/null || true
    
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
    echo "  ✓ WordPress已下载到: $WP_DIR"
else
    echo "  ✓ WordPress目录已存在"
fi

# 步骤2: 配置WordPress
echo ""
echo "[2/5] 配置WordPress..."
if [ ! -f "$WP_DIR/wp-config.php" ]; then
    $SUDO cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php
    
    # 更新数据库配置
    $SUDO sed -i "s/database_name_here/wordpress/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/username_here/wpuser/g" $WP_DIR/wp-config.php
    $SUDO sed -i "s/password_here/wppass123/g" $WP_DIR/wp-config.php
    
    # 启用调试
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_LOG', true);" $WP_DIR/wp-config.php
    $SUDO sed -i "/That's all, stop editing!/i define('WP_DEBUG_DISPLAY', false);" $WP_DIR/wp-config.php
    
    echo "  ✓ WordPress配置完成"
else
    echo "  ✓ WordPress配置文件已存在"
fi

# 步骤3: 安装WP-CLI
echo ""
echo "[3/5] 安装WP-CLI..."
if [ ! -f /usr/local/bin/wp ]; then
    cd /tmp
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>/dev/null || {
        echo "  ⚠ 无法从GitHub下载，尝试备用方法..."
        # 备用下载方式
        wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>/dev/null || {
            echo "  ✗ WP-CLI下载失败，请检查网络"
            echo "  您可以通过浏览器完成WordPress安装"
        }
    }
    
    if [ -f wp-cli.phar ]; then
        $SUDO chmod +x wp-cli.phar
        $SUDO mv wp-cli.phar /usr/local/bin/wp
        echo "  ✓ WP-CLI已安装"
    fi
else
    echo "  ✓ WP-CLI已安装"
fi

# 步骤4: 检查数据库
echo ""
echo "[4/5] 检查数据库..."
if $SUDO mysql -u wpuser -pwppass123 wordpress -e "SELECT 1;" >/dev/null 2>&1; then
    echo "  ✓ 数据库连接正常"
else
    echo "  ⚠ 数据库可能未配置，尝试配置..."
    $SUDO mysql -e "CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
    $SUDO mysql -e "CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppass123';" 2>/dev/null || true
    $SUDO mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';" 2>/dev/null || true
    $SUDO mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true
fi

# 步骤5: 配置Nginx（如果还没有）
echo ""
echo "[5/5] 检查Nginx配置..."

# 确保Nginx目录存在
if [ ! -d /etc/nginx/sites-available ]; then
    echo "  创建Nginx配置目录..."
    $SUDO mkdir -p /etc/nginx/sites-available
    $SUDO mkdir -p /etc/nginx/sites-enabled
fi

if [ ! -f /etc/nginx/sites-enabled/wordpress ]; then
    echo "  配置Nginx..."
    
    # 检测PHP-FPM socket
    PHP_SOCK=$(ls /var/run/php/php*.sock 2>/dev/null | head -1 || echo "/var/run/php/php-fpm.sock")
    if [[ "$PHP_SOCK" == /* ]]; then
        PHP_SOCK="unix:$PHP_SOCK"
    fi
    
    # 创建配置文件
    $SUDO bash -c "cat > /etc/nginx/sites-available/wordpress << 'NGINXEOF'
server {
    listen 80;
    server_name _;
    root /var/www/wordpress;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass $PHP_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
NGINXEOF"
server {
    listen 80;
    server_name _;
    root /var/www/wordpress;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass $PHP_SOCK;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

    $SUDO ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
    $SUDO rm -f /etc/nginx/sites-enabled/default
    $SUDO nginx -t >/dev/null 2>&1 || echo "  ⚠ Nginx配置测试失败"
    echo "  ✓ Nginx已配置"
else
    echo "  ✓ Nginx配置已存在"
fi

# 启动服务
echo ""
echo "启动服务..."
PHP_FPM_SERVICE=$(systemctl list-unit-files | grep -E "php.*-fpm" | head -1 | awk '{print $1}' || echo "php-fpm")
$SUDO systemctl restart nginx mysql $PHP_FPM_SERVICE >/dev/null 2>&1 || true

# 获取IP地址
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo ""
echo "=========================================="
echo "WordPress设置完成！"
echo "=========================================="
echo ""
echo "📍 访问地址："
echo "  http://$IP"
echo ""
echo "📋 下一步："
echo ""
echo "方法1: 通过浏览器安装（推荐）"
echo "  1. 在浏览器访问: http://$IP"
echo "  2. 按照向导完成安装"
echo ""
echo "方法2: 使用WP-CLI安装"
echo "  运行: sudo bash scripts/install-wordpress-cli.sh"
echo ""

