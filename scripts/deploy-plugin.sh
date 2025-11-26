#!/bin/bash

# 部署支付插件到开发环境

set -e

WP_DIR="/var/www/wordpress"
PLUGIN_DIR="$WP_DIR/wp-content/plugins"
PLUGIN_NAME="woocommerce-pay"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "部署支付插件到开发环境"
echo "=========================================="

# 检查WordPress是否存在
if [ ! -d "$WP_DIR" ]; then
    echo "错误: WordPress未安装，请先运行 dev-setup.sh"
    exit 1
fi

# 创建插件目录
if [ -d "$PLUGIN_DIR/$PLUGIN_NAME" ]; then
    echo "删除旧的插件目录..."
    rm -rf "$PLUGIN_DIR/$PLUGIN_NAME"
fi

echo "复制插件文件..."
mkdir -p "$PLUGIN_DIR/$PLUGIN_NAME"
cp -r "$PROJECT_ROOT"/* "$PLUGIN_DIR/$PLUGIN_NAME/" 2>/dev/null || true

# 排除不需要的文件
cd "$PLUGIN_DIR/$PLUGIN_NAME"
rm -rf .git .gitignore node_modules vendor composer.lock *.md scripts/ docs/

# 设置权限
chown -R www-data:www-data "$PLUGIN_DIR/$PLUGIN_NAME"
chmod -R 755 "$PLUGIN_DIR/$PLUGIN_NAME"

# 激活插件（如果WP-CLI可用）
if command -v wp &> /dev/null; then
    cd $WP_DIR
    echo "激活插件..."
    wp plugin activate $PLUGIN_NAME --allow-root || true
fi

echo ""
echo "=========================================="
echo "插件部署完成！"
echo "=========================================="
echo ""
echo "插件位置: $PLUGIN_DIR/$PLUGIN_NAME"
echo ""
echo "下一步:"
echo "  1. 访问 http://localhost/wp-admin"
echo "  2. 进入 插件 > 已安装的插件"
echo "  3. 确认插件已激活"
echo "  4. 进入 WooCommerce > 设置 > 支付 配置支付网关"
echo ""

