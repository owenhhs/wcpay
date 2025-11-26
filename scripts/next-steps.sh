#!/bin/bash

# 安装完成后的下一步指引脚本

echo "=========================================="
echo "安装完成后的下一步"
echo "=========================================="
echo ""

WP_DIR="/var/www/wordpress"
[ ! -d "$WP_DIR" ] && WP_DIR="/var/www/html"

# 获取IP地址
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo "📍 第一步：访问WordPress"
echo "----------------------------------------"
echo "获取IP地址: $IP"
echo ""
echo "在浏览器中访问："
echo "  http://$IP"
echo ""
echo "完成WordPress安装向导："
echo "  - 设置站点标题"
echo "  - 创建管理员账户"
echo "  - 设置密码和邮箱"
echo ""

read -p "按Enter继续查看下一步..."

echo ""
echo "📦 第二步：安装WooCommerce"
echo "----------------------------------------"

if [ -d "$WP_DIR" ] && command -v wp &> /dev/null; then
    cd "$WP_DIR"
    
    if wp plugin is-installed woocommerce --allow-root 2>/dev/null; then
        echo "✓ WooCommerce已安装"
        if ! wp plugin is-active woocommerce --allow-root 2>/dev/null; then
            echo "  激活WooCommerce..."
            sudo wp plugin activate woocommerce --allow-root
        fi
    else
        echo "安装WooCommerce..."
        read -p "是否现在安装？(y/n): " install_wc
        if [ "$install_wc" = "y" ] || [ "$install_wc" = "Y" ]; then
            sudo wp plugin install woocommerce --activate --allow-root
            sudo wp theme install storefront --activate --allow-root
            echo "✓ WooCommerce已安装"
        fi
    fi
else
    echo "⚠ 请通过WordPress后台安装WooCommerce"
    echo "  插件 > 安装插件 > 搜索WooCommerce"
fi

echo ""
read -p "按Enter继续查看下一步..."

echo ""
echo "🔌 第三步：部署支付插件"
echo "----------------------------------------"

PROJECT_DIR=""
POSSIBLE_DIRS=(
    "$HOME/wcpay"
    "$HOME/woocommerce-pay-20251122"
    "/mnt/Users/michael/Desktop/woocommerce-pay-20251122"
    "/host/Users/michael/Desktop/woocommerce-pay-20251122"
)

for dir in "${POSSIBLE_DIRS[@]}"; do
    if [ -d "$dir" ] && [ -f "$dir/includes/class-wc-pix-gateway.php" ]; then
        PROJECT_DIR="$dir"
        break
    fi
done

if [ -n "$PROJECT_DIR" ]; then
    echo "找到项目目录: $PROJECT_DIR"
    
    PLUGIN_DIR="$WP_DIR/wp-content/plugins/woocommerce-pay"
    
    if [ -d "$PLUGIN_DIR" ]; then
        echo "✓ 插件已部署"
    else
        echo "部署插件..."
        read -p "是否现在部署？(y/n): " deploy
        if [ "$deploy" = "y" ] || [ "$deploy" = "Y" ]; then
            sudo cp -r "$PROJECT_DIR" "$PLUGIN_DIR"
            cd "$PLUGIN_DIR"
            sudo rm -rf .git .gitignore node_modules *.md scripts/ docs/ 2>/dev/null || true
            sudo chown -R www-data:www-data "$PLUGIN_DIR"
            sudo chmod -R 755 "$PLUGIN_DIR"
            
            if command -v wp &> /dev/null; then
                cd "$WP_DIR"
                sudo wp plugin activate woocommerce-pay --allow-root
            fi
            
            echo "✓ 插件已部署"
        fi
    fi
else
    echo "⚠ 未找到项目目录"
    echo "请手动部署插件或运行: sudo bash scripts/deploy-plugin.sh"
fi

echo ""
read -p "按Enter继续查看下一步..."

echo ""
echo "⚙️ 第四步：配置PIX支付"
echo "----------------------------------------"
echo ""
echo "在WordPress后台："
echo "  1. 进入 WooCommerce > 设置 > 支付"
echo "  2. 点击 PIX Payment"
echo "  3. 填写API凭证："
echo "     - API Base URL"
echo "     - App ID"
echo "     - Sign Key"
echo "  4. 启用沙盒模式（测试时）"
echo "  5. 启用调试日志"
echo "  6. 保存更改"
echo ""
echo "访问地址: http://$IP/wp-admin"
echo ""

read -p "按Enter继续查看下一步..."

echo ""
echo "🧪 第五步：创建测试产品"
echo "----------------------------------------"

if command -v wp &> /dev/null && [ -d "$WP_DIR" ]; then
    cd "$WP_DIR"
    PRODUCT_COUNT=$(sudo wp wc product list --format=count --allow-root 2>/dev/null || echo "0")
    
    if [ "$PRODUCT_COUNT" -gt "0" ]; then
        echo "✓ 已有 $PRODUCT_COUNT 个产品"
    else
        echo "创建测试产品..."
        read -p "是否现在创建？(y/n): " create_product
        if [ "$create_product" = "y" ] || [ "$create_product" = "Y" ]; then
            sudo wp wc product create \
                --name="测试产品 - PIX支付" \
                --type=simple \
                --regular_price=100.00 \
                --status=publish \
                --allow-root
            echo "✓ 测试产品已创建"
        fi
    fi
else
    echo "⚠ 请通过WordPress后台创建产品"
    echo "  产品 > 添加新产品"
fi

echo ""
read -p "按Enter查看完整指引..."

echo ""
echo "=========================================="
echo "完整指引"
echo "=========================================="
echo ""
echo "查看详细文档："
echo "  cat ~/wcpay/NEXT_STEPS.md"
echo ""
echo "常用命令："
echo "  # 获取IP地址"
echo "  hostname -I"
echo ""
echo "  # 查看订单"
echo "  cd /var/www/wordpress"
echo "  sudo wp wc order list --allow-root"
echo ""
echo "  # 查看日志"
echo "  sudo tail -f /var/www/wordpress/wp-content/debug.log"
echo ""
echo "  # 运行测试"
echo "  cd ~/wcpay"
echo "  sudo bash scripts/test-pix.sh"
echo ""

