#!/bin/bash

# PIX支付功能测试脚本

set -e

WP_DIR="/var/www/wordpress"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "PIX支付功能测试"
echo "=========================================="

# 检查WordPress是否安装
if [ ! -d "$WP_DIR" ] && [ ! -d "/var/www/html" ]; then
    echo "错误: WordPress未安装"
    echo "请先运行: sudo bash scripts/setup-orbstack.sh"
    exit 1
fi

# 确定WordPress目录
if [ -d "$WP_DIR" ]; then
    WP_ROOT="$WP_DIR"
else
    WP_ROOT="/var/www/html"
fi

cd "$WP_ROOT"

# 检查WP-CLI是否可用
if ! command -v wp &> /dev/null; then
    echo "错误: WP-CLI未安装"
    exit 1
fi

echo ""
echo "[1/6] 检查WordPress安装..."
if wp core is-installed --allow-root 2>/dev/null; then
    WP_URL=$(wp option get siteurl --allow-root)
    echo "  ✓ WordPress已安装"
    echo "  URL: $WP_URL"
else
    echo "  ✗ WordPress未安装或未配置"
    echo "  请访问 http://localhost 完成WordPress安装"
    exit 1
fi

echo ""
echo "[2/6] 检查WooCommerce..."
if wp plugin is-installed woocommerce --allow-root 2>/dev/null; then
    WC_VERSION=$(wp plugin get woocommerce --field=version --allow-root)
    echo "  ✓ WooCommerce已安装 (版本: $WC_VERSION)"
    
    if wp plugin is-active woocommerce --allow-root 2>/dev/null; then
        echo "  ✓ WooCommerce已激活"
    else
        echo "  激活WooCommerce..."
        wp plugin activate woocommerce --allow-root
    fi
else
    echo "  ✗ WooCommerce未安装"
    echo "  安装WooCommerce..."
    wp plugin install woocommerce --activate --allow-root
fi

echo ""
echo "[3/6] 检查支付插件..."
PLUGIN_NAME="woocommerce-pay"
if wp plugin is-installed "$PLUGIN_NAME" --allow-root 2>/dev/null; then
    echo "  ✓ 支付插件已安装"
    
    if wp plugin is-active "$PLUGIN_NAME" --allow-root 2>/dev/null; then
        echo "  ✓ 支付插件已激活"
    else
        echo "  激活支付插件..."
        wp plugin activate "$PLUGIN_NAME" --allow-root
    fi
else
    echo "  ✗ 支付插件未安装"
    echo "  请先部署插件: sudo bash scripts/deploy-plugin.sh"
    exit 1
fi

echo ""
echo "[4/6] 检查PIX网关配置..."
PIX_ENABLED=$(wp option get woocommerce_pix_settings --allow-root --format=json 2>/dev/null | grep -o '"enabled":"[^"]*"' | cut -d'"' -f4 || echo "no")

if [ "$PIX_ENABLED" = "yes" ]; then
    echo "  ✓ PIX支付网关已启用"
else
    echo "  ⚠ PIX支付网关未启用"
    echo ""
    echo "  请在WordPress后台配置："
    echo "  WooCommerce > 设置 > 支付 > PIX Payment"
    echo ""
    read -p "  是否现在启用测试配置？(y/n): " enable_now
    
    if [ "$enable_now" = "y" ] || [ "$enable_now" = "Y" ]; then
        echo "  启用PIX网关（测试模式）..."
        wp option update woocommerce_pix_settings '{"enabled":"yes","title":"PIX Payment","description":"Pay with PIX","sandbox":"yes","debug":"yes"}' --format=json --allow-root 2>/dev/null || {
            echo "  ⚠ 无法自动配置，请手动在后台配置"
        }
    fi
fi

echo ""
echo "[5/6] 创建测试产品..."
PRODUCT_EXISTS=$(wp wc product list --format=count --allow-root 2>/dev/null || echo "0")

if [ "$PRODUCT_EXISTS" -gt "0" ]; then
    echo "  ✓ 已有 $PRODUCT_EXISTS 个产品"
    wp wc product list --format=table --allow-root --fields=id,name,price --per_page=5
else
    echo "  创建测试产品..."
    wp wc product create \
        --name="测试产品 - PIX支付" \
        --type=simple \
        --regular_price=100.00 \
        --currency=BRL \
        --description="用于测试PIX支付的产品" \
        --allow-root
    
    if [ $? -eq 0 ]; then
        echo "  ✓ 测试产品创建成功"
    else
        echo "  ✗ 产品创建失败"
    fi
fi

echo ""
echo "[6/6] 检查货币设置..."
CURRENCY=$(wp option get woocommerce_currency --allow-root)
if [ "$CURRENCY" = "BRL" ]; then
    echo "  ✓ 货币设置为BRL"
else
    echo "  ⚠ 货币设置为: $CURRENCY (PIX需要BRL)"
    echo "  更新货币设置..."
    wp option update woocommerce_currency BRL --allow-root
    echo "  ✓ 货币已更新为BRL"
fi

echo ""
echo "=========================================="
echo "环境检查完成"
echo "=========================================="
echo ""
echo "测试步骤："
echo "  1. 访问商店: $WP_URL"
echo "  2. 添加产品到购物车"
echo "  3. 进入结账页面"
echo "  4. 选择PIX支付方式"
echo "  5. 填写订单信息并提交"
echo ""
echo "查看日志："
echo "  sudo tail -f $WP_ROOT/wp-content/debug.log"
echo "  sudo tail -f $WP_ROOT/wp-content/uploads/woocommerce/logs/pix-*.log"
echo ""
echo "WP-CLI命令："
echo "  cd $WP_ROOT"
echo "  wp wc order list --allow-root  # 查看订单"
echo "  wp plugin list --allow-root    # 查看插件"
echo ""

