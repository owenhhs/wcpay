# 支付渠道架构设计文档

## 概述

本插件采用可扩展的多渠道支付架构设计，支持轻松添加新的支付渠道。目前支持以下支付渠道：

- **LarkPay** - 原有支付渠道（已实现）
- **PIX** - 巴西即时支付系统（新实现）

## 架构设计

### 1. 抽象支付渠道基类 (`WC_Payment_Channel`)

**文件路径**: `includes/channels/abstract-wc-payment-channel.php`

所有支付渠道的基类，定义了统一的接口规范：

```php
abstract class WC_Payment_Channel {
    abstract public function create_payment( $order, $posted = array() );
    abstract public function query_payment( $order_id, $transaction_id = '' );
    abstract public function process_ipn( $data );
    abstract public function verify_signature( $data, $headers = array() );
    abstract public function get_supported_currencies();
    abstract protected function get_api_url( $endpoint );
    abstract protected function get_api_headers();
}
```

**优点**:
- 统一的接口规范
- 便于测试和维护
- 易于扩展新渠道

### 2. 具体支付渠道实现

每个支付渠道都有独立的实现类：

#### PIX支付渠道 (`WC_PIX_Channel`)

**文件路径**: `includes/channels/class-wc-pix-channel.php`

实现PIX支付的所有逻辑：
- 创建PIX支付请求
- 查询支付状态
- 处理IPN回调
- 验证签名

**特点**:
- 支持BRL货币
- 自动获取订单信息（CPF/CNPJ、地址等）
- 支持QR码和支付链接

### 3. 支付网关类

每个支付渠道对应一个WooCommerce网关类：

#### PIX网关 (`WC_PIX_Gateway`)

**文件路径**: `includes/class-wc-pix-gateway.php`

继承自 `WC_Payment_Gateway`，负责：
- 网关配置选项
- 支付流程处理
- 订单状态管理
- 收据页面显示

### 4. 插件主类 (`WC_pay`)

**文件路径**: `includes/class-wc-pay.php`

负责：
- 加载所有支付渠道类
- 注册支付网关到WooCommerce
- 管理插件生命周期

## 目录结构

```
includes/
├── channels/                          # 支付渠道目录
│   ├── abstract-wc-payment-channel.php  # 抽象基类
│   └── class-wc-pix-channel.php        # PIX渠道实现
├── class-wc-pay.php                   # 主插件类
├── class-wc-pay-api.php               # LarkPay API类（旧）
├── class-wc-pay-gateway.php           # LarkPay网关（旧）
├── class-wc-pix-gateway.php           # PIX网关（新）
└── class-wc-pay-xml.php               # XML处理类

templates/
├── pix-receipt.php                    # PIX收据页面模板
└── ...                                # 其他模板
```

## 扩展新支付渠道

### 步骤1: 创建渠道类

创建新文件：`includes/channels/class-wc-newchannel-channel.php`

```php
class WC_NewChannel_Channel extends WC_Payment_Channel {
    protected $channel_id = 'newchannel';
    protected $channel_name = 'New Channel';
    
    // 实现所有抽象方法
    public function create_payment( $order, $posted = array() ) {
        // 实现创建支付逻辑
    }
    
    // ... 其他方法
}
```

### 步骤2: 创建网关类

创建新文件：`includes/class-wc-newchannel-gateway.php`

```php
class WC_NewChannel_Gateway extends WC_Payment_Gateway {
    // 实现网关逻辑
    public function __construct() {
        $this->id = 'newchannel';
        // ...
        $this->channel = new WC_NewChannel_Channel( $this );
    }
}
```

### 步骤3: 注册网关

在 `includes/class-wc-pay.php` 中：

```php
private static function includes() {
    // ...
    include_once dirname( __FILE__ ) . '/channels/class-wc-newchannel-channel.php';
    include_once dirname( __FILE__ ) . '/class-wc-newchannel-gateway.php';
}

public static function add_gateway( $methods ) {
    $methods[] = 'WC_NewChannel_Gateway';
    return $methods;
}
```

### 步骤4: 添加配置选项

在网关类的 `init_form_fields()` 方法中添加必要的配置字段。

## 数据流

### 支付流程

```
用户下单
    ↓
选择支付方式（PIX）
    ↓
WC_PIX_Gateway::process_payment()
    ↓
WC_PIX_Channel::create_payment()
    ↓
调用PIX API
    ↓
返回QR码/支付链接
    ↓
显示在收据页面
    ↓
用户完成支付
    ↓
IPN回调
    ↓
WC_PIX_Gateway::check_ipn_response()
    ↓
WC_PIX_Channel::verify_signature()
    ↓
WC_PIX_Channel::process_ipn()
    ↓
更新订单状态
```

## 设计模式

### 1. 策略模式

不同支付渠道作为不同的策略实现：
- `WC_PIX_Channel` - PIX策略
- `WC_LarkPay_Channel` - LarkPay策略（未来可重构）

### 2. 模板方法模式

`WC_Payment_Channel` 基类定义了支付流程的模板，子类实现具体步骤。

### 3. 工厂模式

通过 `WC_pay::add_gateway()` 动态注册支付网关。

## 优势

1. **可扩展性**: 轻松添加新支付渠道
2. **可维护性**: 每个渠道独立，互不影响
3. **可测试性**: 每个组件都可以独立测试
4. **代码复用**: 公共逻辑在基类中实现
5. **向后兼容**: 原有LarkPay渠道保持不变

## 未来改进

1. **重构LarkPay**: 将LarkPay也改为渠道模式
2. **统一配置**: 创建统一的渠道配置管理类
3. **渠道工厂**: 使用工厂模式管理渠道实例
4. **事件系统**: 添加支付事件钩子系统
5. **日志系统**: 统一的日志记录系统

## 注意事项

1. **命名规范**: 
   - 渠道类: `WC_{Channel}_Channel`
   - 网关类: `WC_{Channel}_Gateway`
   - 文件名: `class-wc-{channel}-{type}.php`

2. **错误处理**: 所有渠道必须实现完善的错误处理

3. **安全性**: 所有IPN回调必须验证签名

4. **国际化**: 所有用户可见文本必须可翻译

---

**最后更新**: 2024-01-01

