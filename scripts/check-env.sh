#!/bin/bash

# 环境检查脚本

echo "=========================================="
echo "开发环境检查"
echo "=========================================="

# 检查操作系统
echo -n "操作系统: "
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$NAME $VERSION"
else
    echo "未知"
fi

# 检查Docker
echo -n "Docker: "
if command -v docker &> /dev/null; then
    docker --version
    docker ps &> /dev/null && echo "  ✓ Docker服务运行中" || echo "  ✗ Docker服务未运行"
else
    echo "未安装"
fi

# 检查Docker Compose
echo -n "Docker Compose: "
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    docker-compose --version 2>/dev/null || docker compose version
else
    echo "未安装"
fi

# 检查PHP
echo -n "PHP: "
if command -v php &> /dev/null; then
    php -v | head -n 1
else
    echo "未安装"
fi

# 检查MySQL
echo -n "MySQL: "
if command -v mysql &> /dev/null; then
    mysql --version
    systemctl is-active mysql &> /dev/null && echo "  ✓ MySQL服务运行中" || echo "  ✗ MySQL服务未运行"
else
    echo "未安装"
fi

# 检查Nginx
echo -n "Nginx: "
if command -v nginx &> /dev/null; then
    nginx -v 2>&1
    systemctl is-active nginx &> /dev/null && echo "  ✓ Nginx服务运行中" || echo "  ✗ Nginx服务未运行"
else
    echo "未安装"
fi

# 检查WordPress
echo -n "WordPress: "
if [ -d "/var/www/wordpress" ] || [ -d "/var/www/html" ]; then
    WP_DIR="/var/www/wordpress"
    [ ! -d "$WP_DIR" ] && WP_DIR="/var/www/html"
    
    if [ -f "$WP_DIR/wp-config.php" ]; then
        WP_VERSION=$(grep "wp_version = " "$WP_DIR/wp-includes/version.php" 2>/dev/null | cut -d"'" -f2)
        echo "已安装 (版本: $WP_VERSION)"
        echo "  路径: $WP_DIR"
    else
        echo "目录存在但未配置"
    fi
else
    echo "未安装"
fi

# 检查WooCommerce
echo -n "WooCommerce: "
if command -v wp &> /dev/null; then
    WP_DIR="/var/www/wordpress"
    [ ! -d "$WP_DIR" ] && WP_DIR="/var/www/html"
    
    if [ -d "$WP_DIR" ]; then
        cd "$WP_DIR"
        WC_STATUS=$(wp plugin is-installed woocommerce --allow-root 2>/dev/null)
        if [ "$WC_STATUS" = "1" ]; then
            WC_VERSION=$(wp plugin get woocommerce --field=version --allow-root 2>/dev/null)
            echo "已安装 (版本: $WC_VERSION)"
        else
            echo "未安装"
        fi
    fi
else
    echo "无法检查（需要WP-CLI）"
fi

# 检查插件
echo -n "支付插件: "
PLUGIN_DIR="/var/www/wordpress/wp-content/plugins/woocommerce-pay"
[ ! -d "$PLUGIN_DIR" ] && PLUGIN_DIR="/var/www/html/wp-content/plugins/woocommerce-pay"

if [ -d "$PLUGIN_DIR" ]; then
    echo "已安装"
    echo "  路径: $PLUGIN_DIR"
    if command -v wp &> /dev/null && [ -d "$(dirname "$PLUGIN_DIR")/.." ]; then
        WP_DIR="$(dirname "$PLUGIN_DIR")/../.."
        cd "$WP_DIR"
        ACTIVE=$(wp plugin is-active woocommerce-pay --allow-root 2>/dev/null)
        [ "$ACTIVE" = "1" ] && echo "  状态: 已激活" || echo "  状态: 未激活"
    fi
else
    echo "未安装"
fi

# 检查端口
echo -n "端口占用: "
if command -v netstat &> /dev/null; then
    netstat -tuln | grep -E ":(80|3306|8080)" | awk '{print "  " $4}'
elif command -v ss &> /dev/null; then
    ss -tuln | grep -E ":(80|3306|8080)" | awk '{print "  " $4}'
else
    echo "无法检查"
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="

