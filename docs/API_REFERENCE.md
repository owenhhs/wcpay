# LarkPay API 参考文档

## 概述

本文档描述WooCommerce Pay插件使用的LarkPay API接口。

## 基础信息

### API端点

#### 生产环境
- **Base URL**: `https://gateway.larkpay.com`
- **协议**: HTTPS
- **数据格式**: JSON

#### 测试环境
- **Base URL**: `https://gateway-test.larkpay.com`
- **协议**: HTTPS
- **数据格式**: JSON

### 认证方式

所有API请求使用HTTP Basic Authentication：

```
Authorization: Basic {base64(app_id:secret_key)}
```

**示例**:
```
Authorization: Basic MjAxNzA1MTkxNDE3MjIzNjExMTpURVNUX0FQUF9LRVk=
```

## API接口

### 1. 创建支付订单

创建新的支付订单并获取支付URL。

#### 请求

**端点**: `POST /trade/create`

**请求头**:
```
Content-Type: application/json
Authorization: Basic {base64(app_id:secret_key)}
```

**请求体**:
```json
{
    "app_id": "2017051914172236111",
    "timestamp": "2024-01-01 12:00:00",
    "out_trade_no": "12345",
    "order_currency": "USD",
    "regions": ["BRA"],
    "order_amount": 100.00,
    "subject": "订单标题",
    "content": "订单内容",
    "notify_url": "https://example.com/wc-api/WC_pay_Gateway",
    "return_url": "https://example.com/checkout/order-received/12345/",
    "buyer_id": "customer@example.com",
    "trade_type": "WEB",
    "customer": {
        "name": "John Doe",
        "email": "customer@example.com",
        "phone": "1234567890"
    }
}
```

#### 请求参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用ID |
| timestamp | string | 是 | 时间戳，格式: YYYY-MM-DD HH:ii:ss |
| out_trade_no | string | 是 | 商户订单号，唯一标识 |
| order_currency | string | 是 | 订单货币代码，如USD, BRL |
| regions | array | 是 | 支持的地区代码数组 |
| order_amount | float | 是 | 订单金额 |
| subject | string | 否 | 订单标题 |
| content | string | 否 | 订单内容 |
| notify_url | string | 是 | 异步通知URL |
| return_url | string | 是 | 同步返回URL |
| buyer_id | string | 是 | 买家标识（通常为邮箱） |
| trade_type | string | 是 | 交易类型，WEB表示网页支付 |
| customer | object | 是 | 客户信息 |

#### 地区代码

| 代码 | 国家/地区 |
|------|----------|
| BRA | 巴西 |
| MEX | 墨西哥 |
| CHL | 智利 |
| COL | 哥伦比亚 |
| ARG | 阿根廷 |
| PER | 秘鲁 |
| ECU | 厄瓜多尔 |
| BOL | 玻利维亚 |

#### 响应

**成功响应** (HTTP 200):
```json
{
    "code": "10000",
    "msg": "Success",
    "web_url": "https://gateway.larkpay.com/pay/abc123def456",
    "trade_no": "202401011200001234"
}
```

**错误响应** (HTTP 200):
```json
{
    "code": "40001",
    "msg": "Invalid parameter",
    "data": null
}
```

#### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| code | string | 响应代码，10000表示成功 |
| msg | string | 响应消息 |
| web_url | string | 支付页面URL（成功时） |
| trade_no | string | LarkPay交易号（成功时） |

#### 错误代码

| 代码 | 说明 |
|------|------|
| 10000 | 成功 |
| 40001 | 参数错误 |
| 40002 | 签名错误 |
| 40003 | 订单已存在 |
| 50001 | 服务器错误 |

### 2. 查询订单状态

查询订单的支付状态。

#### 请求

**端点**: `POST /trade/query`

**请求头**:
```
Content-Type: application/json
Authorization: Basic {base64(app_id:secret_key)}
```

**请求体**:
```json
{
    "app_id": "2017051914172236111",
    "timestamp": "2024-01-01 12:00:00",
    "out_trade_no": "12345",
    "trade_no": ""
}
```

#### 请求参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | string | 是 | 应用ID |
| timestamp | string | 是 | 时间戳 |
| out_trade_no | string | 是 | 商户订单号 |
| trade_no | string | 否 | LarkPay交易号 |

#### 响应

**成功响应**:
```json
{
    "code": "10000",
    "msg": "Success",
    "trade_status": "SUCCESS",
    "out_trade_no": "12345",
    "trade_no": "202401011200001234",
    "order_amount": 100.00,
    "pay_time": "2024-01-01 12:05:00"
}
```

#### 支付状态说明

| 状态 | 说明 |
|------|------|
| SUCCESS | 支付成功 |
| PROCESSING | 处理中 |
| REFUSED | 支付被拒绝 |
| CANCEL | 已取消 |
| RISK_CONTROLLING | 风险控制中 |
| DISPUTE | 争议中 |
| REFUND | 退款中 |
| REFUNDED | 已退款 |
| REFUND_MER | 商户退款 |
| REFUND_PRT | 部分退款 |
| CHARGEBACK | 退单 |

### 3. IPN异步通知

LarkPay服务器主动推送的支付状态通知。

#### 通知方式

- **方法**: POST
- **Content-Type**: application/json
- **URL**: 创建订单时指定的notify_url

#### 通知数据

**请求体**:
```json
{
    "out_trade_no": "12345",
    "trade_no": "202401011200001234",
    "trade_status": "SUCCESS",
    "order_amount": 100.00,
    "pay_time": "2024-01-01 12:05:00",
    "refund_amount": 0.00,
    "refund_time": null
}
```

#### 签名验证

**请求头**:
```
HTTP_LARKPAY_SIGNATURE: sign=v1=xxx,sign=v2=abc123def456
```

**验证方法**:
```php
// 1. 从HTTP头获取签名
$header_sign_str = $_SERVER['HTTP_LARKPAY_SIGNATURE'];

// 2. 解析签名（使用v2版本）
$header_sign_arr = explode(',', $header_sign_str);
$header_sign_v2 = explode('=', $header_sign_arr[1]);
$header_sign = $header_sign_v2[1];

// 3. 计算签名
$post_data = file_get_contents('php://input');
$sign = hash_hmac('sha256', $post_data, $secret_key);

// 4. 比较签名
if ($header_sign === $sign) {
    // 验证通过
}
```

#### 响应要求

商户服务器必须返回以下响应：

**成功**: 返回字符串 "success" (HTTP 200)

**失败**: 返回错误信息 (HTTP 200)

**注意**: 
- 必须在5秒内响应
- 如果未收到"success"响应，LarkPay会重试通知
- 重试间隔: 1分钟、5分钟、15分钟、30分钟、1小时、2小时、6小时、12小时

## 数据格式

### 时间格式

所有时间字段使用以下格式：
```
YYYY-MM-DD HH:ii:ss
```

**示例**: `2024-01-01 12:00:00`

### 金额格式

金额使用浮点数，保留2位小数：
```
100.00
```

### 货币代码

使用ISO 4217标准货币代码：
- USD - 美元
- BRL - 巴西雷亚尔
- MXN - 墨西哥比索
- CLP - 智利比索
- COP - 哥伦比亚比索
- ARS - 阿根廷比索
- PEN - 秘鲁索尔
- 等等

## 错误处理

### 错误响应格式

```json
{
    "code": "错误代码",
    "msg": "错误消息",
    "data": null
}
```

### 常见错误

| 错误代码 | 错误消息 | 解决方法 |
|----------|----------|----------|
| 40001 | Invalid parameter | 检查请求参数 |
| 40002 | Signature error | 检查签名计算 |
| 40003 | Order already exists | 使用不同的订单号 |
| 40004 | Invalid amount | 检查订单金额 |
| 40005 | Invalid currency | 检查货币代码 |
| 50001 | Server error | 稍后重试 |
| 50002 | Service unavailable | 联系技术支持 |

## 安全建议

### 1. 使用HTTPS

所有API请求必须使用HTTPS协议。

### 2. 保护Secret Key

- 不要在前端代码中暴露Secret Key
- 不要在日志中记录Secret Key
- 定期更换Secret Key

### 3. 验证签名

所有IPN通知必须验证签名。

### 4. 验证订单金额

在处理IPN通知时，验证订单金额是否匹配。

### 5. 幂等性处理

确保订单处理是幂等的，避免重复处理。

## 限流说明

### 请求频率限制

- **创建订单**: 每分钟最多100次
- **查询订单**: 每分钟最多200次

### 超过限制

如果超过频率限制，API会返回429状态码，需要等待后重试。

## 测试环境

### 测试账户

使用沙盒模式时，可以使用测试账户进行测试。

### 测试数据

- **测试APP ID**: 从LarkPay测试环境获取
- **测试金额**: 可以使用任意金额
- **测试订单号**: 可以使用任意唯一标识

### 测试流程

1. 在插件中启用沙盒模式
2. 使用测试环境API凭证
3. 创建测试订单
4. 使用测试支付方式完成支付
5. 验证IPN回调

## 代码示例

### PHP示例：创建订单

```php
<?php
$app_id = '2017051914172236111';
$secret_key = 'YOUR_SECRET_KEY';
$url = 'https://gateway.larkpay.com/trade/create';

$order_data = array(
    'app_id' => $app_id,
    'timestamp' => date('Y-m-d H:i:s'),
    'out_trade_no' => 'ORDER_' . time(),
    'order_currency' => 'USD',
    'regions' => array('BRA'),
    'order_amount' => 100.00,
    'subject' => 'Test Order',
    'content' => 'Test Order Content',
    'notify_url' => 'https://example.com/notify',
    'return_url' => 'https://example.com/return',
    'buyer_id' => 'customer@example.com',
    'trade_type' => 'WEB',
    'customer' => array(
        'name' => 'John Doe',
        'email' => 'customer@example.com',
        'phone' => '1234567890'
    )
);

$header = array(
    'Content-Type: application/json',
    'Authorization: Basic ' . base64_encode($app_id . ':' . $secret_key)
);

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($order_data));
curl_setopt($ch, CURLOPT_HTTPHEADER, $header);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, true);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

$result = json_decode($response, true);

if ($result['code'] == '10000') {
    // 成功，重定向到支付页面
    header('Location: ' . $result['web_url']);
} else {
    // 失败，显示错误
    echo 'Error: ' . $result['msg'];
}
?>
```

### PHP示例：验证IPN签名

```php
<?php
function verify_ipn_signature($post_data, $secret_key) {
    // 获取HTTP头中的签名
    if (!isset($_SERVER['HTTP_LARKPAY_SIGNATURE'])) {
        return false;
    }
    
    $header_sign_str = $_SERVER['HTTP_LARKPAY_SIGNATURE'];
    
    // 解析签名（使用v2版本）
    $header_sign_arr = explode(',', $header_sign_str);
    if (count($header_sign_arr) < 2) {
        return false;
    }
    
    $header_sign_v2 = explode('=', $header_sign_arr[1]);
    if (count($header_sign_v2) < 2) {
        return false;
    }
    
    $header_sign = $header_sign_v2[1];
    
    // 计算签名
    $sign = hash_hmac('sha256', $post_data, $secret_key);
    
    // 比较签名
    return hash_equals($header_sign, $sign);
}

// 使用示例
$post_data = file_get_contents('php://input');
$secret_key = 'YOUR_SECRET_KEY';

if (verify_ipn_signature($post_data, $secret_key)) {
    // 签名验证通过
    $data = json_decode($post_data, true);
    
    // 处理订单状态更新
    // ...
    
    // 返回成功响应
    echo 'success';
} else {
    // 签名验证失败
    http_response_code(401);
    echo 'signature error';
}
?>
```

## 更新日志

### API版本历史

- **v1.0**: 初始版本
- **v1.1**: 添加多地区支持
- **v1.2**: 改进签名验证

## 技术支持

如有API相关问题，请联系：
- **LarkPay技术支持**: support@larkpay.com
- **API文档**: https://docs.larkpay.com/

---

**最后更新**: 2024-01-01

