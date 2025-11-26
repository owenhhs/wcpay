#!/bin/bash

# 修复Nginx配置

set -e

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

echo "=========================================="
echo "修复Nginx配置"
echo "=========================================="
echo ""

# 步骤0: 检查并安装Nginx
echo "[0/4] 检查Nginx安装..."
if ! command -v nginx &> /dev/null; then
    echo "  Nginx未安装，正在安装..."
    $SUDO apt-get update -qq >/dev/null 2>&1
    $SUDO apt-get install -y -qq nginx >/dev/null 2>&1
    
    if command -v nginx &> /dev/null; then
        echo "  ✓ Nginx已安装"
    else
        echo "  ✗ Nginx安装失败"
        exit 1
    fi
else
    echo "  ✓ Nginx已安装"
fi

# 启动并启用Nginx服务
$SUDO systemctl start nginx >/dev/null 2>&1 || true
$SUDO systemctl enable nginx >/dev/null 2>&1 || true

# 创建目录
echo ""
echo "[1/4] 创建Nginx配置目录..."
$SUDO mkdir -p /etc/nginx/sites-available
$SUDO mkdir -p /etc/nginx/sites-enabled
echo "✓ 目录已创建"

# 检测PHP-FPM socket
echo ""
echo ""
echo "[2/4] 检测PHP-FPM socket..."
PHP_SOCK=$(ls /var/run/php/php*.sock 2>/dev/null | head -1 || echo "")

if [ -z "$PHP_SOCK" ]; then
    # 尝试查找PHP-FPM服务
    PHP_FPM_SERVICE=$(systemctl list-unit-files | grep -E "php.*-fpm" | head -1 | awk '{print $1}' || echo "")
    
    if [ -n "$PHP_FPM_SERVICE" ]; then
        # 根据服务名推测socket路径
        if echo "$PHP_FPM_SERVICE" | grep -q "8.3"; then
            PHP_SOCK="/var/run/php/php8.3-fpm.sock"
        elif echo "$PHP_FPM_SERVICE" | grep -q "8.2"; then
            PHP_SOCK="/var/run/php/php8.2-fpm.sock"
        elif echo "$PHP_FPM_SERVICE" | grep -q "8.1"; then
            PHP_SOCK="/var/run/php/php8.1-fpm.sock"
        else
            PHP_SOCK="/var/run/php/php-fpm.sock"
        fi
    else
        PHP_SOCK="/var/run/php/php-fpm.sock"
    fi
fi

# 转换为nginx格式
if [[ "$PHP_SOCK" == /* ]]; then
    PHP_SOCK_NGINX="unix:$PHP_SOCK"
else
    PHP_SOCK_NGINX="$PHP_SOCK"
fi

echo "  使用socket: $PHP_SOCK_NGINX"

# 创建Nginx配置
echo ""
echo "[3/4] 创建Nginx配置..."

$SUDO bash -c "cat > /etc/nginx/sites-available/wordpress << 'NGINXEOF'
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
        fastcgi_pass $PHP_SOCK_NGINX;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINXEOF"

# 启用站点
$SUDO ln -sf /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
$SUDO rm -f /etc/nginx/sites-enabled/default

# 测试配置
echo "  测试Nginx配置..."
if $SUDO nginx -t 2>/dev/null; then
    echo "  ✓ Nginx配置正确"
else
    echo "  ⚠ Nginx配置测试失败，查看错误："
    $SUDO nginx -t
fi

# 测试并重启Nginx
echo ""
echo "[4/4] 测试并重启Nginx..."
if $SUDO nginx -t >/dev/null 2>&1; then
    echo "  ✓ 配置测试通过"
    $SUDO systemctl restart nginx >/dev/null 2>&1 || true
    echo "  ✓ Nginx已重启"
else
    echo "  ⚠ 配置测试失败，查看详情："
    $SUDO nginx -t || true
    echo "  ⚠ 尝试继续重启..."
    $SUDO systemctl restart nginx >/dev/null 2>&1 || true
fi

echo ""
echo "=========================================="
echo "Nginx配置完成！"
echo "=========================================="
echo ""
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
echo "📍 访问地址："
echo "  http://$IP"
echo ""
echo "现在可以访问WordPress了"
echo ""

