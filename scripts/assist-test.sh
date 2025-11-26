#!/bin/bash

# 测试协助脚本 - 交互式引导

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "PIX支付插件测试协助"
echo "=========================================="
echo ""

# 检查当前环境
echo "步骤1: 检查环境..."
echo ""

# 检查是否在Ubuntu环境中
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "✓ 运行在: $NAME"
    
    # 检查WordPress是否安装
    if [ -d "/var/www/wordpress" ] || [ -d "/var/www/html" ]; then
        WP_DIR="/var/www/wordpress"
        [ ! -d "$WP_DIR" ] && WP_DIR="/var/www/html"
        echo "✓ WordPress目录存在: $WP_DIR"
        
        if [ -f "$WP_DIR/wp-config.php" ]; then
            echo "✓ WordPress已配置"
            
            # 检查WP-CLI
            if command -v wp &> /dev/null; then
                cd "$WP_DIR"
                if wp core is-installed --allow-root 2>/dev/null; then
                    WP_URL=$(wp option get siteurl --allow-root 2>/dev/null || echo "未设置")
                    echo "✓ WordPress已安装"
                    echo "  URL: $WP_URL"
                else
                    echo "⚠ WordPress未完全安装"
                fi
            fi
        else
            echo "⚠ WordPress未配置"
        fi
    else
        echo "✗ WordPress未安装"
    fi
else
    echo "⚠ 未检测到Linux环境"
    echo "  您可能需要在OrbStack Ubuntu环境中运行此脚本"
fi

echo ""
echo "=========================================="
echo "选择操作："
echo "=========================================="
echo ""
echo "1. 检查环境状态"
echo "2. 设置开发环境（首次运行）"
echo "3. 运行完整测试"
echo "4. 测试API连接"
echo "5. 查看日志"
echo "6. 手动测试步骤"
echo "7. 退出"
echo ""
read -p "请选择 (1-7): " choice

case $choice in
    1)
        echo ""
        echo "运行环境检查..."
        bash "$PROJECT_DIR/scripts/check-env.sh"
        ;;
    2)
        echo ""
        echo "开始设置开发环境..."
        echo "这可能需要几分钟时间..."
        sudo bash "$PROJECT_DIR/scripts/setup-orbstack.sh"
        echo ""
        echo "环境设置完成！"
        echo "下一步：运行安装WooCommerce和部署插件"
        read -p "是否现在安装WooCommerce？(y/n): " install_wc
        if [ "$install_wc" = "y" ] || [ "$install_wc" = "Y" ]; then
            sudo bash "$PROJECT_DIR/scripts/install-woocommerce.sh"
            echo ""
            read -p "是否现在部署插件？(y/n): " deploy
            if [ "$deploy" = "y" ] || [ "$deploy" = "Y" ]; then
                sudo bash "$PROJECT_DIR/scripts/deploy-plugin.sh"
            fi
        fi
        ;;
    3)
        echo ""
        echo "运行完整测试..."
        sudo bash "$PROJECT_DIR/scripts/test-pix.sh"
        ;;
    4)
        echo ""
        echo "测试API连接..."
        sudo bash "$PROJECT_DIR/scripts/test-api.sh"
        ;;
    5)
        echo ""
        echo "查看日志..."
        echo ""
        echo "选择要查看的日志："
        echo "1. WordPress调试日志"
        echo "2. PIX支付日志"
        echo "3. PHP错误日志"
        echo "4. Nginx错误日志"
        echo "5. 所有日志（实时）"
        read -p "请选择 (1-5): " log_choice
        
        WP_DIR="/var/www/wordpress"
        [ ! -d "$WP_DIR" ] && WP_DIR="/var/www/html"
        
        case $log_choice in
            1)
                echo ""
                echo "WordPress调试日志:"
                echo "-------------------"
                sudo tail -50 "$WP_DIR/wp-content/debug.log" 2>/dev/null || echo "日志文件不存在"
                ;;
            2)
                echo ""
                echo "PIX支付日志:"
                echo "-------------------"
                sudo tail -50 "$WP_DIR/wp-content/uploads/woocommerce/logs/pix-"*.log 2>/dev/null || echo "日志文件不存在"
                ;;
            3)
                echo ""
                echo "PHP错误日志:"
                echo "-------------------"
                sudo tail -50 /var/log/php8.1-fpm.log 2>/dev/null || echo "日志文件不存在"
                ;;
            4)
                echo ""
                echo "Nginx错误日志:"
                echo "-------------------"
                sudo tail -50 /var/log/nginx/wordpress_error.log 2>/dev/null || echo "日志文件不存在"
                ;;
            5)
                echo ""
                echo "实时查看所有日志 (Ctrl+C退出)..."
                sudo tail -f \
                    "$WP_DIR/wp-content/debug.log" \
                    "$WP_DIR/wp-content/uploads/woocommerce/logs/pix-"*.log \
                    /var/log/php8.1-fpm.log \
                    /var/log/nginx/wordpress_error.log 2>/dev/null || echo "部分日志文件不存在"
                ;;
        esac
        ;;
    6)
        echo ""
        echo "=========================================="
        echo "手动测试步骤"
        echo "=========================================="
        echo ""
        
        # 获取IP地址
        IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        
        echo "1. 访问WordPress:"
        echo "   http://$IP"
        echo ""
        
        echo "2. 配置PIX支付网关:"
        echo "   登录管理后台 → WooCommerce > 设置 > 支付 > PIX Payment"
        echo "   填写API凭证并启用"
        echo ""
        
        echo "3. 创建测试订单:"
        echo "   - 访问商店首页"
        echo "   - 添加产品到购物车"
        echo "   - 进入结账页面"
        echo "   - 选择PIX支付方式"
        echo "   - 填写订单信息并提交"
        echo ""
        
        echo "4. 查看订单:"
        echo "   cd /var/www/wordpress"
        echo "   sudo wp wc order list --allow-root"
        echo ""
        
        echo "5. 查看日志:"
        echo "   sudo tail -f /var/www/wordpress/wp-content/debug.log"
        echo ""
        ;;
    7)
        echo ""
        echo "退出"
        exit 0
        ;;
    *)
        echo ""
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "操作完成"
echo "=========================================="
echo ""

