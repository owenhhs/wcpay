#!/bin/bash

# 自动完整设置脚本 - 一键安装所有组件

set -e

echo "=========================================="
echo "自动完整环境设置"
echo "=========================================="
echo ""
echo "这将安装以下组件："
echo "  - PHP 8.1 及相关扩展"
echo "  - MySQL 数据库"
echo "  - Nginx Web服务器"
echo "  - WordPress"
echo "  - WP-CLI"
echo ""
echo "预计需要 5-10 分钟"
echo ""
read -p "是否继续？(y/n): " proceed

if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "开始安装..."
echo ""

# 运行环境设置脚本
if [ -f "scripts/setup-orbstack.sh" ]; then
    echo "[1/3] 运行环境设置脚本..."
    sudo bash scripts/setup-orbstack.sh
else
    echo "✗ 未找到 setup-orbstack.sh"
    exit 1
fi

echo ""
echo "[2/3] 安装WooCommerce..."
if [ -f "scripts/install-woocommerce.sh" ]; then
    sudo bash scripts/install-woocommerce.sh
else
    echo "⚠ 未找到 install-woocommerce.sh，跳过"
fi

echo ""
echo "[3/3] 部署插件..."
if [ -f "scripts/deploy-plugin.sh" ]; then
    sudo bash scripts/deploy-plugin.sh
else
    echo "⚠ 未找到 deploy-plugin.sh，跳过"
fi

echo ""
echo "=========================================="
echo "环境设置完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "  1. 获取IP地址: hostname -I"
echo "  2. 访问: http://[IP地址]"
echo "  3. 完成WordPress安装向导"
echo "  4. 配置PIX支付网关"
echo ""
echo "查看测试脚本："
echo "  sudo bash scripts/test-pix.sh"
echo ""

