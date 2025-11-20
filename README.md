# LarkPay for WooCommerce

**Contributors**: LarkPay R&D team  
**Tags**: woocommerce, larkpay, payment  
**Requires at least**: WordPress 5.0, WooCommerce 3.0  
**Tested up to**: WordPress 6.4, WooCommerce 8.0  
**Stable tag**: 1.1.4  
**License**: GPL v2 or later  
**License URI**: https://www.gnu.org/licenses/gpl-2.0.html

## 项目概述

这是一个为 WordPress WooCommerce 开发的支付网关插件，集成 LarkPay 支付服务。该插件支持多种支付方式，包括信用卡、银行转账和票据支付，主要面向拉美市场。

## 基本信息

- **插件名称**: LarkPay for WooCommerce (pay)
- **版本**: 1.1.4
- **开发者**: LarkPay R&D team
- **原作者**: Claudio Sanches
- **兼容性**: WordPress 5.0+ + WooCommerce 3.0+
- **主要功能**: LarkPay 支付网关集成

## 功能特性

### 1. 支付方式支持
- ✅ 信用卡支付
- ✅ 银行转账
- ✅ 票据支付（Boleto）
- ✅ 透明结账（Transparent Checkout）

### 2. 地区支持
插件支持以下拉美国家/地区：
- 🇧🇷 巴西 (BRA)
- 🇲🇽 墨西哥 (MEX)
- 🇨🇱 智利 (CHL)
- 🇨🇴 哥伦比亚 (COL)
- 🇦🇷 阿根廷 (ARG)
- 🇵🇪 秘鲁 (PER)
- 🇪🇨 厄瓜多尔 (ECU)
- 🇧🇴 玻利维亚 (BOL)

### 3. 核心功能
- 沙盒模式支持（测试环境）
- IPN（即时支付通知）处理
- 订单状态自动更新
- 支付日志记录
- 多语言支持
- 调试模式

## 项目结构

```
woocommerce-pay-20250508/
├── docs/                      # 文档目录
│   ├── DOCUMENTATION.md       # 技术文档
│   ├── INSTALLATION.md        # 安装配置指南
│   ├── API_REFERENCE.md       # API参考文档
│   └── PROJECT_SUMMARY.md    # 项目总结
├── assets/                    # 静态资源文件
│   ├── css/                   # 样式文件
│   │   └── frontend/          # 前端样式
│   ├── images/                # 图片资源
│   └── js/                    # JavaScript文件
│       └── admin/             # 后台管理脚本
├── includes/                  # 核心类文件
│   ├── admin/                 # 后台管理相关
│   │   └── views/             # 管理界面视图
│   ├── class-wc-pay.php      # 主插件类
│   ├── class-wc-pay-gateway.php  # 支付网关类
│   ├── class-wc-pay-api.php  # API处理类
│   ├── class-wc-pay-xml.php  # XML处理类
│   └── views/                 # 前端视图
├── languages/                 # 语言文件
├── templates/                 # 模板文件
│   ├── emails/               # 邮件模板
│   └── ...                   # 其他模板
├── README.md                  # 项目主文档（本文件）
└── woocommerce-pay.php       # 插件主文件
```

## 文档导航

本项目包含完整的文档，位于 `docs/` 目录：

- 📖 **[技术文档](docs/DOCUMENTATION.md)** - 详细的架构设计、核心类说明、API集成、支付流程等
- 🔧 **[安装配置指南](docs/INSTALLATION.md)** - 系统要求、安装步骤、配置说明、常见问题
- 📡 **[API参考文档](docs/API_REFERENCE.md)** - API端点说明、请求/响应格式、代码示例
- 📋 **[项目总结](docs/PROJECT_SUMMARY.md)** - 项目概述、技术栈、功能清单、文档索引

**快速开始**: 建议先阅读 [安装配置指南](docs/INSTALLATION.md)

## 核心类说明

### 1. WC_pay (主插件类)
**文件**: `includes/class-wc-pay.php`

**主要职责**:
- 插件初始化
- 加载文本域（多语言）
- 注册支付网关
- 添加管理链接
- 处理地区限制（巴西）

**关键方法**:
- `init()`: 初始化插件
- `add_gateway()`: 添加支付网关到WooCommerce
- `hides_when_is_outside_brazil()`: 根据地区隐藏支付方式
- `load_plugin_textdomain()`: 加载翻译文件

### 2. WC_pay_Gateway (支付网关类)
**文件**: `includes/class-wc-pay-gateway.php`

**主要职责**:
- 支付网关配置
- 处理支付请求
- 处理IPN回调
- 更新订单状态
- 管理支付表单

**关键方法**:
- `process_payment()`: 处理支付请求
- `check_ipn_response()`: 处理IPN回调
- `receipt_page()`: 显示收据页面
- `GatewaySign()`: 验证网关签名
- `curl_post_json_header()`: 发送API请求

**支付状态处理**:
- `SUCCESS`: 订单完成
- `REFUND/REFUND_MER/REFUND_PRT`: 退款
- `REFUSED`: 支付被拒绝
- `CANCEL`: 支付取消
- `RISK_CONTROLLING`: 风险控制中
- `DISPUTE`: 争议处理
- `REFUNDED`: 已退款
- `CHARGEBACK`: 退单

### 3. WC_pay_API (API处理类)
**文件**: `includes/class-wc-pay-api.php`

**主要职责**:
- 与LarkPay API通信
- 处理支付请求
- 处理IPN通知
- 获取会话ID
- 错误处理

**关键方法**:
- `do_request()`: 执行API请求
- `do_checkout_request()`: 创建结账请求
- `do_payment_request()`: 创建支付请求
- `process_ipn_request()`: 处理IPN请求
- `get_session_id()`: 获取会话ID
- `get_error_message()`: 获取错误消息

### 4. WC_pay_XML (XML处理类)
**文件**: `includes/class-wc-pay-xml.php`

**主要职责**:
- 构建XML请求
- 处理订单数据
- 格式化支付信息

**关键方法**:
- `add_sender_data()`: 添加发送者数据
- `add_shipping_data()`: 添加配送数据
- `add_items()`: 添加订单项
- `add_credit_card_data()`: 添加信用卡数据
- `render()`: 渲染XML

## 配置说明

### 必需配置项

1. **APP ID**: LarkPay应用ID
2. **Secret Key**: 密钥
3. **Public Key**: 公钥

### 沙盒配置

- **Sandbox APP ID**: 测试环境应用ID
- **Sandbox Secret Key**: 测试环境密钥
- **Sandbox Public Key**: 测试环境公钥

### 其他配置

- **Title**: 支付方式显示标题
- **Description**: 支付方式描述
- **Sandbox Mode**: 是否启用沙盒模式
- **Debug Log**: 是否启用调试日志

## API端点

### 生产环境
- Gateway URL: `https://gateway.larkpay.com`
- 创建订单: `/trade/create`
- 查询订单: `/trade/query`

### 测试环境
- Gateway URL: `https://gateway-test.larkpay.com`

## 支付流程

### 1. 订单创建流程
```
用户提交订单 
  → process_payment() 
  → 构建订单数据 
  → 调用 /trade/create API 
  → 获取支付URL 
  → 重定向到支付页面
```

### 2. IPN回调流程
```
LarkPay发送IPN通知 
  → check_ipn_response() 
  → 验证签名 
  → 解析支付状态 
  → 更新订单状态
```

### 3. 订单查询流程
```
用户访问收据页面 
  → receipt_page() 
  → 调用 /trade/query API 
  → 显示支付状态
```

## 安全特性

1. **签名验证**: 使用HMAC-SHA256验证IPN请求
2. **HTTPS通信**: 所有API请求使用HTTPS
3. **数据验证**: 严格验证输入数据
4. **CSRF保护**: WordPress内置CSRF保护

## 依赖项

### 必需插件
- **WooCommerce**: 核心电商插件

### 推荐插件
- **Extra Checkout Fields for Brazil**: 用于透明结账功能（可选）

## 安装说明

1. 将插件文件夹上传到 `/wp-content/plugins/` 目录
2. 在WordPress后台激活插件
3. 进入 WooCommerce → 设置 → 支付 → pay
4. 配置API凭证
5. 启用支付网关

## 使用说明

### 配置支付网关

1. 登录WordPress后台
2. 进入 **WooCommerce** → **设置** → **支付**
3. 找到 **pay** 支付方式
4. 点击 **管理** 或 **设置**
5. 填写以下信息：
   - APP ID
   - Secret Key
   - Public Key
   - 沙盒凭证（如使用测试环境）
6. 保存设置

### 测试支付

1. 启用沙盒模式
2. 使用测试凭证
3. 创建测试订单
4. 检查日志文件（如启用调试）

## 调试

### 启用调试日志

1. 在支付网关设置中启用"Debug Log"
2. 日志文件位置：
   - WooCommerce 2.2+: `WooCommerce → 状态 → 日志`
   - 旧版本: `wp-content/uploads/woocommerce/logs/`

### 常见问题排查

1. **支付失败**: 检查API凭证是否正确
2. **IPN未接收**: 检查服务器是否可访问
3. **订单状态未更新**: 检查IPN回调URL配置
4. **签名验证失败**: 检查Secret Key是否正确

## 代码示例

### 创建支付请求

```php
$order_data = array(
    "app_id" => $this->app_id(),
    "timestamp" => date('Y-m-d H:i:s', time()),
    "out_trade_no" => $order_id,
    "order_currency" => get_woocommerce_currency(),
    "regions" => array($regions),
    "order_amount" => $order->get_total(),
    "notify_url" => add_query_arg('wc-api', 'WC_pay_Gateway', home_url('/')),
    "return_url" => $order->get_checkout_order_received_url(true),
    "buyer_id" => $_POST['billing_email'],
    "trade_type" => 'WEB',
    "customer" => array(
        "name" => $customer_name,
        "email" => $_POST['billing_email'],
        "phone" => $_POST['billing_phone'],
    ),
);
```

### 验证IPN签名

```php
private function GatewaySign($post_data) {
    $header_sign_str = $_SERVER['HTTP_LARKPAY_SIGNATURE'];
    $header_sign_arr = explode(',', $header_sign_str);
    $header_sign_v2 = explode('=', $header_sign_arr['1']);
    $header_sign = $header_sign_v2['1'];
    $sign = hash_hmac('sha256', $post_data, $this->secret_key());
    
    return $header_sign == $sign;
}
```

## 支付状态映射

| LarkPay状态 | WooCommerce状态 | 说明 |
|-------------|----------------|------|
| SUCCESS | completed | 支付成功 |
| REFUND/REFUND_MER/REFUND_PRT | refunded | 退款 |
| REFUSED | failed | 支付被拒绝 |
| CANCEL | cancelled | 支付取消 |
| RISK_CONTROLLING | pending | 风险控制中 |
| DISPUTE | pending | 争议处理 |
| REFUNDED | refunded | 已退款 |
| CHARGEBACK | processing | 退单 |

## 注意事项

1. **地区限制**: 插件主要针对拉美市场，特别是巴西
2. **货币支持**: 支持多种货币，但主要针对当地货币
3. **必需字段**: 某些支付方式需要额外的客户信息（如CPF/CNPJ）
4. **API限制**: 注意API调用频率限制
5. **SSL要求**: 生产环境建议使用SSL证书

## 更新日志

### 版本 1.1.4
- 当前版本
- 支持多地区支付
- 改进IPN处理
- 增强安全性

## 技术支持

如有问题，请：
1. 查看调试日志
2. 检查API凭证
3. 联系LarkPay技术支持

## 许可证

请查看插件文件中的许可证信息。

## 贡献者

- LarkPay R&D team

---

**注意**: 本插件需要有效的LarkPay账户和API凭证才能正常工作。

