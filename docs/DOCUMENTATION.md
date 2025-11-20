# WooCommerce Pay 插件技术文档

## 目录

1. [架构设计](#架构设计)
2. [核心类详解](#核心类详解)
3. [API集成](#api集成)
4. [支付流程详解](#支付流程详解)
5. [数据流](#数据流)
6. [安全机制](#安全机制)
7. [错误处理](#错误处理)
8. [扩展开发](#扩展开发)

## 架构设计

### 整体架构

```
┌─────────────────────────────────────────┐
│         WordPress/WooCommerce           │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│          WC_pay (主插件类)              │
│  - 插件初始化                            │
│  - 网关注册                              │
│  - 钩子管理                              │
└─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌──────────────┐      ┌──────────────────┐
│ WC_pay_      │      │   WC_pay_API     │
│ Gateway      │◄────►│   - API通信      │
│ - 支付处理    │      │   - 请求构建     │
│ - 订单管理    │      │   - 响应解析     │
│ - 状态更新    │      └──────────────────┘
└──────────────┘              │
        │                     │
        ▼                     ▼
┌──────────────┐      ┌──────────────────┐
│ WC_pay_XML   │      │   LarkPay API   │
│ - XML构建    │      │   - 支付网关      │
│ - 数据格式化  │      │   - IPN回调      │
└──────────────┘      └──────────────────┘
```

### 类关系图

```
WC_pay
  ├── 初始化 WC_pay_Gateway
  │     ├── 使用 WC_pay_API
  │     │     └── 使用 WC_pay_XML
  │     └── 处理支付和IPN
  └── 注册钩子和过滤器
```

## 核心类详解

### WC_pay 类

#### 类职责
- 插件生命周期管理
- WooCommerce集成
- 多语言支持
- 网关注册

#### 关键方法

```php
// 初始化插件
public static function init()

// 添加支付网关
public static function add_gateway($methods)

// 根据地区过滤网关
public static function hides_when_is_outside_brazil($available_gateways)

// 加载翻译文件
public static function load_plugin_textdomain()
```

#### 钩子使用

```php
// 插件加载后初始化
add_action('plugins_loaded', array('WC_pay', 'init'));

// 添加支付网关
add_filter('woocommerce_payment_gateways', array(__CLASS__, 'add_gateway'));

// 过滤可用网关
add_filter('woocommerce_available_payment_gateways', 
    array(__CLASS__, 'hides_when_is_outside_brazil'));
```

### WC_pay_Gateway 类

#### 类职责
- 支付网关配置
- 支付请求处理
- IPN回调处理
- 订单状态管理

#### 配置字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| enabled | checkbox | 启用/禁用 |
| title | text | 支付方式标题 |
| description | textarea | 支付方式描述 |
| app_id | text | 应用ID |
| secret_key | text | 密钥 |
| public_key | text | 公钥 |
| sandbox | checkbox | 沙盒模式 |
| debug | checkbox | 调试日志 |

#### 关键方法

##### process_payment()

处理支付请求的主要方法。

```php
public function process_payment($order_id) {
    // 1. 获取订单对象
    $order = wc_get_order($order_id);
    
    // 2. 构建订单数据
    $order_data = array(
        "app_id" => $this->app_id(),
        "timestamp" => date('Y-m-d H:i:s', time()),
        "out_trade_no" => $order_id,
        "order_currency" => get_woocommerce_currency(),
        "regions" => array($regions),
        "order_amount" => $order->get_total(),
        // ...
    );
    
    // 3. 发送API请求
    $curl = $this->gateway_url().'/trade/create';
    $pag_response = $this->curl_post_json_header($curl, $order_data);
    
    // 4. 处理响应
    if ($pag_response['code'] == "10000") {
        // 成功：重定向到支付页面
        return array(
            'result' => 'success',
            'redirect' => $pag_response['web_url']
        );
    } else {
        // 失败：显示错误
        wc_add_notice($pag_response['msg'], 'error');
        return array('result' => 'fail');
    }
}
```

##### check_ipn_response()

处理IPN回调的方法。

```php
public function check_ipn_response() {
    // 1. 获取POST数据
    $data = json_decode(file_get_contents('php://input'), true);
    
    // 2. 验证签名
    $sign = $this->GatewaySign(file_get_contents('php://input'));
    
    // 3. 获取订单
    $order_id = $data['out_trade_no'];
    $order = wc_get_order($order_id);
    
    // 4. 根据状态更新订单
    switch($data['trade_status']) {
        case 'SUCCESS':
            $order->update_status('completed');
            break;
        case 'REFUSED':
            $order->update_status('failed');
            break;
        // ...
    }
}
```

##### GatewaySign()

验证IPN请求签名。

```php
private function GatewaySign($post_data) {
    // 1. 获取HTTP头中的签名
    $header_sign_str = $_SERVER['HTTP_LARKPAY_SIGNATURE'];
    
    // 2. 解析签名
    $header_sign_arr = explode(',', $header_sign_str);
    $header_sign_v2 = explode('=', $header_sign_arr['1']);
    $header_sign = $header_sign_v2['1'];
    
    // 3. 计算签名
    $sign = hash_hmac('sha256', $post_data, $this->secret_key());
    
    // 4. 比较签名
    return $header_sign == $sign;
}
```

### WC_pay_API 类

#### 类职责
- API通信封装
- 请求构建
- 响应解析
- 错误处理

#### 关键方法

##### do_request()

执行HTTP请求的通用方法。

```php
protected function do_request($url, $method = 'POST', $data = array(), $headers = array()) {
    $params = array(
        'method' => $method,
        'timeout' => 60,
    );
    
    if ('POST' == $method && !empty($data)) {
        $params['body'] = $data;
    }
    
    if (!empty($headers)) {
        $params['headers'] = $headers;
    }
    
    return wp_safe_remote_post($url, $params);
}
```

##### get_session_id()

获取透明结账所需的会话ID。

```php
public function get_session_id() {
    $url = add_query_arg(
        array(
            'email' => $this->gateway->get_email(),
            'token' => $this->gateway->get_token()
        ),
        $this->get_sessions_url()
    );
    
    $response = $this->do_request($url, 'POST');
    
    // 解析XML响应
    $session = $this->safe_load_xml($response['body'], LIBXML_NOCDATA);
    
    if (isset($session->id)) {
        return (string) $session->id;
    }
    
    return false;
}
```

### WC_pay_XML 类

#### 类职责
- XML文档构建
- 数据格式化
- CDATA处理

#### 关键方法

##### add_sender_data()

添加发送者（客户）数据到XML。

```php
public function add_sender_data($order, $hash = '') {
    $name = $order->get_billing_first_name() . ' ' . $order->get_billing_last_name();
    $sender = $this->addChild('sender');
    $sender->addChild('email')->add_cdata($order->get_billing_email());
    
    // 添加CPF或CNPJ
    if (/* CPF条件 */) {
        $this->add_cpf($order->get_meta('_billing_cpf'), $sender);
    } else if (/* CNPJ条件 */) {
        $this->add_cnpj($order->get_meta('_billing_cnpj'), $sender);
    }
    
    $sender->addChild('name')->add_cdata($name);
    
    // 添加电话
    if ('' !== $order->get_billing_phone()) {
        $phone_number = $this->get_numbers($order->get_billing_phone());
        $phone = $sender->addChild('phone');
        $phone->addChild('areaCode', substr($phone_number, 0, 2));
        $phone->addChild('number', substr($phone_number, 2));
    }
    
    if ('' != $hash) {
        $sender->addChild('hash', $hash);
    }
}
```

## API集成

### API端点

#### 生产环境

| 端点 | URL | 方法 | 说明 |
|------|-----|------|------|
| 创建订单 | `https://gateway.larkpay.com/trade/create` | POST | 创建支付订单 |
| 查询订单 | `https://gateway.larkpay.com/trade/query` | POST | 查询订单状态 |

#### 测试环境

| 端点 | URL | 方法 | 说明 |
|------|-----|------|------|
| 创建订单 | `https://gateway-test.larkpay.com/trade/create` | POST | 创建支付订单（测试） |
| 查询订单 | `https://gateway-test.larkpay.com/trade/query` | POST | 查询订单状态（测试） |

### 认证方式

使用HTTP Basic Authentication：

```php
$header = array(
    'Content-Type: application/json',
    'Authorization: Basic ' . base64_encode($app_id . ':' . $secret_key)
);
```

### 请求格式

#### 创建订单请求

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

#### 创建订单响应

```json
{
    "code": "10000",
    "msg": "Success",
    "web_url": "https://gateway.larkpay.com/pay/...",
    "trade_no": "202401011200001234"
}
```

#### IPN通知格式

```json
{
    "out_trade_no": "12345",
    "trade_no": "202401011200001234",
    "trade_status": "SUCCESS",
    "order_amount": 100.00,
    "pay_time": "2024-01-01 12:05:00"
}
```

#### IPN请求头

```
HTTP_LARKPAY_SIGNATURE: sign=v1=xxx,sign=v2=abc123def456
```

## 支付流程详解

### 标准支付流程

```
┌─────────┐
│  用户   │
└────┬────┘
     │ 1. 选择商品并结账
     ▼
┌─────────────────┐
│ WooCommerce     │
│ Checkout Page   │
└────┬────────────┘
     │ 2. 选择pay支付方式
     ▼
┌─────────────────┐
│ process_payment │
│ (创建订单)      │
└────┬────────────┘
     │ 3. 构建订单数据
     ▼
┌─────────────────┐
│ /trade/create   │
│ API请求         │
└────┬────────────┘
     │ 4. 返回支付URL
     ▼
┌─────────────────┐
│ LarkPay        │
│ 支付页面        │
└────┬────────────┘
     │ 5. 用户完成支付
     ▼
┌─────────────────┐
│ IPN回调         │
│ check_ipn_      │
│ response()      │
└────┬────────────┘
     │ 6. 验证签名并更新订单
     ▼
┌─────────────────┐
│ 订单状态更新    │
│ completed/      │
│ failed/etc      │
└─────────────────┘
```

### 订单查询流程

```
┌─────────┐
│  用户   │
└────┬────┘
     │ 1. 访问订单详情页
     ▼
┌─────────────────┐
│ receipt_page()  │
└────┬────────────┘
     │ 2. 构建查询请求
     ▼
┌─────────────────┐
│ /trade/query    │
│ API请求         │
└────┬────────────┘
     │ 3. 返回订单状态
     ▼
┌─────────────────┐
│ 显示支付状态    │
│ (lightbox)      │
└─────────────────┘
```

## 数据流

### 订单数据流

```
WooCommerce Order
    │
    ├─→ 订单基本信息
    │   ├─ order_id
    │   ├─ total
    │   ├─ currency
    │   └─ customer info
    │
    ├─→ WC_pay_Gateway::process_payment()
    │   └─→ 构建 order_data 数组
    │
    ├─→ curl_post_json_header()
    │   └─→ JSON编码
    │
    └─→ LarkPay API
        └─→ 返回 web_url
```

### IPN数据流

```
LarkPay服务器
    │
    ├─→ POST到 notify_url
    │   ├─ JSON body
    │   └─ HTTP_LARKPAY_SIGNATURE header
    │
    ├─→ WC_pay_Gateway::check_ipn_response()
    │   ├─→ 读取POST数据
    │   ├─→ GatewaySign()验证
    │   └─→ 解析 trade_status
    │
    └─→ 更新订单状态
        ├─ SUCCESS → completed
        ├─ REFUSED → failed
        └─ ...
```

## 安全机制

### 1. 签名验证

IPN请求使用HMAC-SHA256签名验证：

```php
// 计算签名
$sign = hash_hmac('sha256', $post_data, $secret_key);

// 从HTTP头获取签名
$header_sign = $_SERVER['HTTP_LARKPAY_SIGNATURE'];
// 格式: sign=v1=xxx,sign=v2=abc123

// 验证
if ($header_sign == $sign) {
    // 验证通过
}
```

### 2. HTTPS通信

所有API请求使用HTTPS加密传输。

### 3. 数据验证

- 订单ID验证
- 金额验证
- 客户信息验证
- 必填字段检查

### 4. 错误处理

```php
// 签名验证失败
if (!$sign) {
    $order->update_status('pending', '签名验证失败');
    echo "sign error";
    exit();
}

// API请求失败
if ($pag_response['code'] != "10000") {
    wc_add_notice($pag_response['msg'], 'error');
    $order->update_status('cancelled');
    return array('result' => 'fail');
}
```

## 错误处理

### 错误代码

| 代码 | 说明 | 处理方式 |
|------|------|----------|
| 10000 | 成功 | 继续处理 |
| 其他 | 错误 | 显示错误消息 |

### 常见错误

1. **签名验证失败**
   - 原因: Secret Key不匹配
   - 处理: 检查配置中的Secret Key

2. **订单创建失败**
   - 原因: API凭证错误或数据格式错误
   - 处理: 检查API凭证和订单数据

3. **IPN未接收**
   - 原因: 服务器无法访问或URL配置错误
   - 处理: 检查notify_url配置和服务器可访问性

### 调试模式

启用调试日志：

```php
// 在设置中启用
$this->debug = 'yes';

// 记录日志
if ('yes' === $this->debug) {
    $this->log->add($this->id, '日志消息');
}
```

日志位置：
- WooCommerce 2.2+: `WooCommerce → 状态 → 日志`
- 文件路径: `wp-content/uploads/woocommerce/logs/pay-{hash}.log`

## 扩展开发

### 添加自定义支付方式

```php
// 在 WC_pay_Gateway 中添加
public function init_form_fields() {
    $this->form_fields['custom_method'] = array(
        'title' => __('Custom Method', 'woocommerce-pay'),
        'type' => 'checkbox',
        'label' => __('Enable Custom Method', 'woocommerce-pay'),
        'default' => 'no',
    );
}
```

### 自定义订单数据

使用过滤器：

```php
// 在 process_payment() 中
$order_data = apply_filters('wc_pay_order_data', $order_data, $order);
```

### 自定义IPN处理

```php
// 添加自定义状态处理
add_action('woocommerce_pay_ipn_custom_status', function($order, $data) {
    // 自定义处理逻辑
}, 10, 2);
```

### 添加自定义模板

```php
// 覆盖模板
add_filter('woocommerce_locate_template', function($template, $template_name) {
    if ('woocommerce/pay/custom-template.php' === $template_name) {
        $template = plugin_dir_path(__FILE__) . 'templates/custom-template.php';
    }
    return $template;
}, 10, 2);
```

## 最佳实践

1. **始终验证签名**: 确保所有IPN请求都经过签名验证
2. **使用HTTPS**: 生产环境必须使用HTTPS
3. **启用日志**: 开发阶段启用调试日志
4. **错误处理**: 妥善处理所有可能的错误情况
5. **测试沙盒**: 在生产环境前充分测试沙盒环境
6. **数据验证**: 验证所有输入数据
7. **安全存储**: 安全存储API凭证

## 性能优化

1. **缓存会话ID**: 避免频繁请求会话ID
2. **异步处理**: IPN处理可以异步化
3. **数据库优化**: 优化订单查询
4. **减少API调用**: 合理使用订单查询API

## 故障排查

### 问题: 支付无法完成

1. 检查API凭证是否正确
2. 检查网络连接
3. 查看调试日志
4. 验证订单数据格式

### 问题: IPN未接收

1. 检查notify_url是否可访问
2. 验证服务器防火墙设置
3. 检查SSL证书
4. 查看服务器错误日志

### 问题: 订单状态未更新

1. 检查IPN回调是否正常
2. 验证签名验证逻辑
3. 查看订单状态更新日志
4. 检查WooCommerce订单状态设置

---

**文档版本**: 1.0  
**最后更新**: 2024-01-01

