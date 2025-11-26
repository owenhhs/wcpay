# PIX支付通道集成文档

## 概述

本文档描述如何集成和使用PIX支付通道。PIX是巴西的即时支付系统，允许用户通过银行应用进行实时支付。

## 架构设计

为了支持多个支付渠道，我们采用了以下架构设计：

### 1. 抽象支付渠道基类 (`WC_Payment_Channel`)

所有支付渠道都需要继承自 `WC_Payment_Channel` 抽象类，并实现以下方法：

- `create_payment()` - 创建支付请求
- `query_payment()` - 查询支付状态
- `process_ipn()` - 处理IPN回调
- `verify_signature()` - 验证签名
- `get_supported_currencies()` - 获取支持的货币
- `get_api_url()` - 获取API端点URL
- `get_api_headers()` - 获取API请求头

### 2. 具体支付渠道实现

每个支付渠道都有自己的实现类：

- `WC_PIX_Channel` - PIX支付渠道
- 未来可以添加更多渠道，如：`WC_CreditCard_Channel`, `WC_Boleto_Channel` 等

### 3. 支付网关类

每个支付渠道对应一个WooCommerce网关类：

- `WC_PIX_Gateway` - PIX支付网关

## PIX支付配置

### API凭证配置

在WooCommerce后台配置页面（WooCommerce > Settings > Checkout > PIX Payment），需要配置以下信息：

1. **API Base URL** - PIX API的基础URL
2. **App ID** - 应用ID，用于身份验证
3. **Sign Key** - 签名密钥，用于签名验证
4. **Sandbox Mode** - 是否启用沙盒模式

### API文档

PIX支付API文档地址：
- 文档链接: https://s.apifox.cn/5bba2671-7bd9-4078-9cac-5074cd3bb826?pwd=5F6R083g
- 密码: `5F6R083g`

## 支付请求格式

### 创建支付请求

**端点**: `POST /payment/create`

**请求示例**:
```json
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
        "email": "Test2312321@gmail.com",
        "phone": "32132131232313",
        "nationalId": "47418692021"
    },
    "type": "PIX",
    "card": {
        "firstName": "Michael",
        "lastName": "Jaskcon"
    },
    "currency": "BRL",
    "orderNo": "25062900023",
    "deviceInfo": {
        "clientIp": "127.0.0.1",
        "language": "en-US"
    }
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| amount | string | 是 | 支付金额（格式：10.01） |
| billing | object | 是 | 账单信息 |
| billing.address | object | 是 | 地址信息（可写固定值） |
| billing.email | string | 是 | 用户邮箱（需用户填写） |
| billing.phone | string | 是 | 用户电话（需用户填写） |
| billing.nationalId | string | 是 | 身份证号CPF/CNPJ（需用户填写） |
| type | string | 是 | 支付类型，固定值："PIX" |
| card | object | 是 | 持卡人信息 |
| card.firstName | string | 是 | 名字（需用户填写） |
| card.lastName | string | 是 | 姓氏（需用户填写） |
| currency | string | 是 | 货币代码，固定值："BRL" |
| orderNo | string | 是 | 订单号（不可重复） |
| deviceInfo | object | 是 | 设备信息 |
| deviceInfo.clientIp | string | 是 | 客户端IP（系统获取） |
| deviceInfo.language | string | 是 | 语言，固定值："en-US" |

**注意事项**:
- `billing.address` 字段可以写固定值
- `billing.email`, `billing.phone`, `billing.nationalId` 需要从订单中获取用户填写的信息
- `card.firstName`, `card.lastName` 需要从订单中获取用户填写的信息
- `deviceInfo.clientIp` 系统自动获取
- `orderNo` 必须唯一，不可重复

### 查询支付状态

**端点**: `POST /payment/query`

**请求参数**:
- `orderNo` - 订单号
- `transactionId` - 交易ID（可选）

### IPN回调

**回调URL**: `{your-site-url}/wc-api/wc_pix_gateway`

**签名验证**:
- 请求头: `X-Signature`
- 算法: HMAC-SHA256
- 签名内容: 原始POST数据
- 密钥: Sign Key

## 响应处理

### 成功响应

```json
{
    "code": "SUCCESS",
    "transactionId": "xxx",
    "qrCode": "xxxxx",
    "paymentLink": "https://..."
}
```

### 错误响应

```json
{
    "code": "ERROR",
    "message": "Error message"
}
```

## 订单状态映射

PIX支付状态与WooCommerce订单状态的映射关系：

| PIX状态 | WooCommerce状态 | 说明 |
|---------|----------------|------|
| SUCCESS / PAID / COMPLETED | completed | 支付成功 |
| FAILED / REFUSED | failed | 支付失败 |
| PENDING / PROCESSING | pending | 支付处理中 |
| CANCELLED / CANCEL | cancelled | 支付已取消 |

## 使用流程

1. **用户下单**: 用户在结账页面选择PIX支付方式
2. **创建支付**: 系统调用PIX API创建支付请求
3. **显示QR码**: 在订单确认页面显示PIX QR码或支付链接
4. **用户支付**: 用户使用银行应用扫描QR码或点击支付链接完成支付
5. **IPN回调**: PIX服务器发送支付结果到回调URL
6. **订单更新**: 系统验证签名并更新订单状态

## 扩展新支付渠道

要添加新的支付渠道，请按以下步骤：

1. **创建渠道类**: 继承 `WC_Payment_Channel` 类
   ```php
   class WC_NewChannel extends WC_Payment_Channel {
       // 实现抽象方法
   }
   ```

2. **创建网关类**: 继承 `WC_Payment_Gateway` 类
   ```php
   class WC_NewChannel_Gateway extends WC_Payment_Gateway {
       // 实现网关逻辑
   }
   ```

3. **注册网关**: 在 `WC_pay::add_gateway()` 方法中添加新网关

4. **配置选项**: 在网关类的 `init_form_fields()` 方法中添加配置字段

## 测试

### 沙盒模式

启用沙盒模式进行测试：

1. 在网关配置页面启用"Sandbox Mode"
2. 使用测试环境的API凭证
3. 进行测试支付

### 日志调试

启用调试日志：

1. 在网关配置页面启用"Debug Log"
2. 查看日志: WooCommerce > Status > Logs

## 安全建议

1. **使用HTTPS**: 所有API请求必须使用HTTPS
2. **保护密钥**: 不要在前端暴露API密钥
3. **验证签名**: 所有IPN回调必须验证签名
4. **验证金额**: 处理IPN时验证订单金额
5. **幂等性**: 确保订单处理是幂等的，避免重复处理

## 故障排查

### 常见问题

1. **支付无法创建**
   - 检查API凭证是否正确
   - 检查网络连接
   - 查看调试日志

2. **IPN未接收**
   - 检查回调URL是否可访问
   - 检查服务器防火墙设置
   - 验证SSL证书

3. **签名验证失败**
   - 检查Sign Key是否正确
   - 验证签名算法是否匹配
   - 检查请求数据格式

## 技术支持

如有问题，请联系技术支持或查看API文档。

---

**最后更新**: 2024-01-01

