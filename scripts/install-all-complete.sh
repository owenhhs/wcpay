#!/bin/bash

# 完整安装脚本 - 包括WooCommerce和插件

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "完整环境安装（包括WooCommerce和插件）"
echo "=========================================="
echo ""

# 先运行基础安装
if [ -f "$SCRIPT_DIR/install-all.sh" ]; then
    echo "步骤1: 安装基础环境..."
    bash "$SCRIPT_DIR/install-all.sh"
else
    echo "✗ 未找到 install-all.sh"
    exit 1
fi

echo ""
echo "=========================================="
echo "步骤2: 安装WooCommerce"
echo "=========================================="

WP_DIR="/var/www/wordpress"
cd "$WP_DIR"

# 检查WP-CLI
if ! command -v wp &> /dev/null; then
    echo "⚠ WP-CLI未安装，跳过WooCommerce自动安装"
    echo "请手动安装WooCommerce"
else
    echo "安装WooCommerce..."
    sudo wp plugin install woocommerce --activate --allow-root 2>/dev/null || {
        echo "  ⚠ WooCommerce安装失败，可能需要先完成WordPress安装"
    }
    
    echo "安装Storefront主题..."
    sudo wp theme install storefront --activate --allow-root 2>/dev/null || echo "  主题安装失败"
fi

echo ""

echo "=========================================="
echo "步骤3: 部署支付插件"
echo "=========================================="

if [ -d "$PROJECT_DIR/includes" ]; then
    PLUGIN_DIR="$WP_DIR/wp-content/plugins/woocommerce-pay"
    
    if [ -d "$PLUGIN_DIR" ]; then
        echo "删除旧的插件目录..."
        sudo rm -rf "$PLUGIN_DIR"
    fi
    
    echo "复制插件文件..."
    sudo cp -r "$PROJECT_DIR" "$PLUGIN_DIR" 2>/dev/null || {
        echo "  ⚠ 复制失败，请手动复制"
    }
    
    # 排除不需要的文件
    cd "$PLUGIN_DIR"
    sudo rm -rf .git .gitignore node_modules vendor composer.lock *.md scripts/ docs/ 2>/dev/null || true
    
    # 设置权限
    sudo chown -R www-data:www-data "$PLUGIN_DIR"
    sudo chmod -R 755 "$PLUGIN_DIR"
    
    echo "✓ 插件已部署"
    
    # 尝试激活插件
    if command -v wp &> /dev/null; then
        echo "激活插件..."
        cd "$WP_DIR"
        sudo wp plugin activate woocommerce-pay --allow-root 2>/dev/null || {
            echo "  ⚠ 插件激活失败，可能需要先完成WordPress安装"
        }
    fi
else
    echo "⚠ 未找到插件文件"
    echo "请确保在项目目录中运行此脚本"
fi

echo ""
echo "=========================================="
echo "安装完成！"
echo "=========================================="
echo ""

IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo "访问地址："
echo "  WordPress: http://$IP"
echo "  管理后台: http://$IP/wp-admin"
echo ""
echo "下一步："
echo "  1. 访问 http://$IP 完成WordPress安装向导"
echo "  2. 配置WooCommerce（货币选择BRL）"
echo "  3. 配置PIX支付网关"
echo "  4. 运行测试: sudo bash scripts/test-pix.sh"
echo ""

