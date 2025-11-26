#!/bin/bash

# Docker环境完整设置脚本（在容器启动后运行）

set -e

CONTAINER_NAME="wp-dev-wordpress"

echo "=========================================="
echo "配置Docker中的WordPress"
echo "=========================================="
echo ""

# 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "✗ WordPress容器未运行"
    echo "请先运行: bash docker/docker-start.sh"
    exit 1
fi

echo "[1/4] 等待WordPress就绪..."
sleep 5

echo ""
echo "[2/4] 安装WordPress（如果尚未安装）..."
docker exec -it $CONTAINER_NAME wp core install \
    --url=http://localhost:8080 \
    --title="WooCommerce Store" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root 2>/dev/null || {
    echo "  WordPress已安装或安装失败"
}

echo ""
echo "[3/4] 安装WooCommerce..."
docker exec -it $CONTAINER_NAME wp plugin install woocommerce --activate --allow-root 2>/dev/null || {
    echo "  WooCommerce已安装或安装失败"
}

echo ""
echo "[4/4] 检查支付插件..."
if [ -d "/var/www/html/wp-content/plugins/woocommerce-pay" ]; then
    echo "  ✓ 支付插件已挂载"
    docker exec -it $CONTAINER_NAME wp plugin activate woocommerce-pay --allow-root 2>/dev/null || {
        echo "  ⚠ 激活插件失败，请手动激活"
    }
else
    echo "  ⚠ 支付插件未找到"
fi

echo ""
echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "📍 访问地址："
echo "  前台: http://localhost:8080"
echo "  后台: http://localhost:8080/wp-admin"
echo ""
echo "登录信息："
echo "  用户名: admin"
echo "  密码: admin123"
echo ""
echo "⚠️  重要：请立即更改密码！"
echo ""

