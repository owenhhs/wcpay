#!/bin/bash

# WordPress安装脚本

set -e

echo "=========================================="
echo "WordPress安装"
echo "=========================================="
echo ""

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

WP_DIR="/var/www/wordpress"

# 检查WordPress是否已下载
if [ ! -d "$WP_DIR" ]; then
    echo "[1/4] 下载WordPress..."
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
    echo "✓ WordPress目录已存在: $WP_DIR"
fi

# 配置WordPress
if [ ! -f "$WP_DIR/wp-config.php" ]; then
    echo ""
    echo "[2/4] 配置WordPress..."
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
else
    echo "✓ WordPress配置文件已存在"
fi

# 检查数据库
echo ""
echo "[3/4] 检查数据库..."
if $SUDO mysql -u wpuser -pwppass123 wordpress -e "SELECT 1;" >/dev/null 2>&1; then
    echo "  ✓ 数据库连接正常"
else
    echo "  ⚠ 数据库连接失败，请检查MySQL配置"
fi

# 检查服务
echo ""
echo "[4/4] 检查服务状态..."
NGINX_STATUS=$($SUDO systemctl is-active nginx 2>/dev/null || echo "inactive")
MYSQL_STATUS=$($SUDO systemctl is-active mysql 2>/dev/null || echo "inactive")

# 检测PHP-FPM服务
PHP_FPM_SERVICE=$(systemctl list-unit-files | grep -E "php.*-fpm" | head -1 | awk '{print $1}' || echo "php-fpm")
PHP_FPM_STATUS=$($SUDO systemctl is-active $PHP_FPM_SERVICE 2>/dev/null || echo "inactive")

echo "  Nginx: $NGINX_STATUS"
echo "  MySQL: $MYSQL_STATUS"
echo "  PHP-FPM: $PHP_FPM_STATUS"

if [ "$NGINX_STATUS" != "active" ]; then
    echo "  启动Nginx..."
    $SUDO systemctl start nginx
fi

if [ "$MYSQL_STATUS" != "active" ]; then
    echo "  启动MySQL..."
    $SUDO systemctl start mysql
fi

if [ "$PHP_FPM_STATUS" != "active" ]; then
    echo "  启动PHP-FPM..."
    $SUDO systemctl start $PHP_FPM_SERVICE
fi

# 获取IP地址
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo ""
echo "=========================================="
echo "WordPress安装完成！"
echo "=========================================="
echo ""
echo "📍 访问地址："
echo "  WordPress: http://$IP"
echo "  管理后台: http://$IP/wp-admin"
echo ""
echo "📋 下一步："
echo "  1. 在浏览器中访问 http://$IP"
echo "  2. 按照向导完成WordPress安装："
echo "     - 选择语言"
echo "     - 填写站点标题"
echo "     - 创建管理员账户（用户名和密码）"
echo "     - 输入邮箱"
echo "     - 点击'安装WordPress'"
echo ""
echo "💾 数据库信息（如果需要）："
echo "  数据库: wordpress"
echo "  用户: wpuser"
echo "  密码: wppass123"
echo ""

