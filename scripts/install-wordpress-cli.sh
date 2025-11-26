#!/bin/bash

# 使用WP-CLI安装WordPress

set -e

WP_DIR="/var/www/wordpress"

echo "=========================================="
echo "使用WP-CLI安装WordPress"
echo "=========================================="
echo ""

# 检查WordPress目录
if [ ! -d "$WP_DIR" ]; then
    echo "✗ WordPress目录不存在"
    echo "请先运行: sudo bash scripts/setup-wordpress-now.sh"
    exit 1
fi

cd "$WP_DIR"

# 检查WP-CLI
if ! command -v wp &> /dev/null; then
    echo "安装WP-CLI..."
    cd /tmp
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar || {
        echo "下载失败，请检查网络"
        exit 1
    }
    sudo chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
fi

echo "✓ WP-CLI已就绪"
echo ""

# 检查是否已安装
if wp core is-installed --allow-root 2>/dev/null; then
    echo "WordPress已安装"
    echo ""
    echo "站点信息:"
    wp option get siteurl --allow-root
    echo ""
    echo "要重新安装，请先删除数据库或使用不同配置"
    exit 0
fi

# 获取IP地址
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo "安装WordPress..."
echo "URL: http://$IP"
echo ""

# 安装WordPress
sudo wp core install \
    --url="http://$IP" \
    --title="My WooCommerce Store" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root

echo ""
echo "=========================================="
echo "WordPress安装完成！"
echo "=========================================="
echo ""
echo "访问地址："
echo "  前台: http://$IP"
echo "  后台: http://$IP/wp-admin"
echo ""
echo "登录信息："
echo "  用户名: admin"
echo "  密码: admin123"
echo ""
echo "⚠️  重要：请立即登录并更改密码！"
echo ""
echo "下一步："
echo "  1. 登录后台更改密码"
echo "  2. 安装WooCommerce"
echo "  3. 部署支付插件"
echo ""

