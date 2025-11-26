#!/bin/bash

# 仅安装PHP - 跳过PPA，使用系统PHP

set -e

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

echo "=========================================="
echo "安装PHP（使用系统仓库）"
echo "=========================================="
echo ""

# 移除可能已添加的有问题的PPA
echo "[1/3] 清理PPA..."
$SUDO add-apt-repository --remove ppa:ondrej/php 2>/dev/null || true
$SUDO apt-get update -qq

echo "[2/3] 安装系统PHP..."
# 直接安装系统默认PHP，不添加PPA
$SUDO apt-get install -y \
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
    php-opcache

echo ""
echo "[3/3] 检查安装..."
php -v | head -1

# 检测PHP-FPM服务
PHP_FPM_SERVICE=$(systemctl list-unit-files | grep php.*fpm | head -1 | awk '{print $1}' || echo "php-fpm")
echo "PHP-FPM服务: $PHP_FPM_SERVICE"

# 检测socket路径
PHP_SOCK=$(ls /var/run/php/php*.sock 2>/dev/null | head -1 || echo "/var/run/php/php-fpm.sock")
echo "PHP-FPM Socket: $PHP_SOCK"

echo ""
echo "=========================================="
echo "PHP安装完成！"
echo "=========================================="
echo ""
echo "现在可以继续安装其他组件："
echo "  sudo bash scripts/install-all.sh"
echo ""

