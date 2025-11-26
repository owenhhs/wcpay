#!/bin/bash

# PIX API连接测试脚本

set -e

echo "=========================================="
echo "PIX API连接测试"
echo "=========================================="

# 从WordPress配置读取API凭证
WP_DIR="/var/www/wordpress"
[ ! -d "$WP_DIR" ] && WP_DIR="/var/www/html"

if [ ! -f "$WP_DIR/wp-config.php" ]; then
    echo "错误: WordPress未安装"
    exit 1
fi

cd "$WP_DIR"

# 读取配置
if command -v wp &> /dev/null; then
    PIX_SETTINGS=$(wp option get woocommerce_pix_settings --allow-root --format=json 2>/dev/null || echo "{}")
    
    API_BASE_URL=$(echo "$PIX_SETTINGS" | grep -o '"pix_api_base_url":"[^"]*"' | cut -d'"' -f4 || echo "")
    APP_ID=$(echo "$PIX_SETTINGS" | grep -o '"pix_app_id":"[^"]*"' | cut -d'"' -f4 || echo "")
    SIGN_KEY=$(echo "$PIX_SETTINGS" | grep -o '"pix_sign_key":"[^"]*"' | cut -d'"' -f4 || echo "")
else
    API_BASE_URL=""
    APP_ID=""
    SIGN_KEY=""
fi

# 如果配置为空，提示输入
if [ -z "$API_BASE_URL" ] || [ -z "$APP_ID" ] || [ -z "$SIGN_KEY" ]; then
    echo ""
    echo "未找到API配置，请手动输入："
    read -p "API Base URL: " API_BASE_URL
    read -p "App ID: " APP_ID
    read -s -p "Sign Key: " SIGN_KEY
    echo ""
fi

if [ -z "$API_BASE_URL" ] || [ -z "$APP_ID" ] || [ -z "$SIGN_KEY" ]; then
    echo "错误: API凭证不完整"
    exit 1
fi

echo ""
echo "测试配置："
echo "  API Base URL: $API_BASE_URL"
echo "  App ID: $APP_ID"
echo "  Sign Key: ${SIGN_KEY:0:10}..."
echo ""

# 生成认证头
AUTH_STR=$(echo -n "$APP_ID:$SIGN_KEY" | base64)

# 测试连接
echo "[1/3] 测试API连接..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET \
    "$API_BASE_URL/health" \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $AUTH_STR" \
    --connect-timeout 10 \
    2>&1) || {
    echo "  ✗ 连接失败"
    echo "  请检查："
    echo "    - API Base URL是否正确"
    echo "    - 网络连接是否正常"
    echo "    - 服务器是否可访问"
    exit 1
}

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "  HTTP状态码: $HTTP_CODE"

if [ "$HTTP_CODE" -eq "200" ] || [ "$HTTP_CODE" -eq "404" ]; then
    echo "  ✓ API服务器可访问"
else
    echo "  ⚠ API返回状态码: $HTTP_CODE"
fi

# 测试创建支付（使用测试数据）
echo ""
echo "[2/3] 测试创建支付请求..."
TEST_DATA=$(cat <<EOF
{
    "amount": "10.01",
    "billing": {
        "address": {
            "city": "R11",
            "country": "BRA",
            "neighborhood": "212",
            "number": "3213",
            "line1": "2311312",
            "postcode": "12345678",
            "region": "MG"
        },
        "email": "test@example.com",
        "phone": "32132131232313",
        "nationalId": "47418692021"
    },
    "type": "PIX",
    "card": {
        "firstName": "Michael",
        "lastName": "Jackson"
    },
    "currency": "BRL",
    "orderNo": "TEST$(date +%s)",
    "deviceInfo": {
        "clientIp": "127.0.0.1",
        "language": "en-US"
    }
}
EOF
)

echo "  发送测试请求到: $API_BASE_URL/payment/create"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "$API_BASE_URL/payment/create" \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $AUTH_STR" \
    -d "$TEST_DATA" \
    --connect-timeout 10 \
    2>&1) || {
    echo "  ✗ 请求失败"
    exit 1
}

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

echo "  HTTP状态码: $HTTP_CODE"
echo "  响应内容:"
echo "$BODY" | python3 -m json.tool 2>/dev/null || echo "$BODY"

if [ "$HTTP_CODE" -eq "200" ]; then
    echo "  ✓ 支付请求创建成功"
    
    # 检查响应中的关键字段
    if echo "$BODY" | grep -q "transactionId\|qrCode\|paymentLink"; then
        echo "  ✓ 响应包含有效字段"
    fi
else
    echo "  ⚠ API返回错误"
    echo "  请检查API凭证和请求格式"
fi

# 测试签名验证
echo ""
echo "[3/3] 测试签名生成..."
TEST_DATA_STR='{"test":"data"}'
SIGNATURE=$(echo -n "$TEST_DATA_STR" | openssl dgst -sha256 -hmac "$SIGN_KEY" -binary | base64 2>/dev/null || \
    echo -n "$TEST_DATA_STR" | openssl sha256 -hmac "$SIGN_KEY" 2>/dev/null | cut -d' ' -f2)

if [ -n "$SIGNATURE" ]; then
    echo "  ✓ 签名生成成功"
    echo "  测试签名: ${SIGNATURE:0:20}..."
else
    echo "  ⚠ 签名生成失败"
fi

echo ""
echo "=========================================="
echo "API测试完成"
echo "=========================================="
echo ""
echo "如果测试失败，请检查："
echo "  1. API凭证是否正确"
echo "  2. API Base URL是否正确"
echo "  3. 网络连接是否正常"
echo "  4. API文档中的端点路径是否正确"
echo ""

