#!/bin/bash

# WooCommerce 安装脚本

set -e

WP_DIR="/var/www/wordpress"
PLUGIN_DIR="$WP_DIR/wp-content/plugins"

echo "=========================================="
echo "安装 WooCommerce"
echo "=========================================="

# 检查WordPress是否存在
if [ ! -d "$WP_DIR" ]; then
    echo "错误: WordPress未安装，请先运行 dev-setup.sh"
    exit 1
fi

cd $WP_DIR

# 检查WP-CLI是否可用
if ! command -v wp &> /dev/null; then
    echo "错误: WP-CLI未安装"
    exit 1
fi

echo "下载并安装 WooCommerce..."
wp plugin install woocommerce --activate --allow-root

echo "下载并安装 WooCommerce Admin..."
wp plugin install woocommerce-admin --activate --allow-root

echo "下载并安装 Storefront 主题（WooCommerce官方主题）..."
wp theme install storefront --activate --allow-root

echo ""
echo "=========================================="
echo "WooCommerce 安装完成！"
echo "=========================================="
echo ""
echo "请访问 http://localhost/wp-admin 完成WooCommerce设置向导"
echo ""

