# PIX支付快速开始指南

## 简介

本指南帮助您快速配置和使用PIX支付通道。

## 前置要求

1. WooCommerce已安装并配置
2. 已获取PIX支付API凭证：
   - API Base URL
   - App ID
   - Sign Key
3. 支持BRL货币的WooCommerce商店

## 配置步骤

### 1. 启用PIX支付网关

1. 登录WordPress后台
2. 进入 `WooCommerce > Settings > Checkout`
3. 找到 `PIX Payment` 支付方式
4. 点击进入配置页面

### 2. 配置API凭证

在配置页面填写以下信息：

- **Enable/Disable**: 勾选启用PIX支付
- **Title**: 支付方式显示名称（如：PIX Payment）
- **Description**: 支付方式描述
- **Sandbox Mode**: 是否启用沙盒模式（测试时启用）
- **API Base URL**: PIX API的基础URL
  - 示例: `https://api.example.com`
- **App ID**: 您的PIX API应用ID
- **Sign Key**: 您的PIX API签名密钥

### 3. 启用调试日志（可选）

如果遇到问题，可以启用调试日志：

1. 勾选 `Debug Log`
2. 查看日志: `WooCommerce > Status > Logs`

## 使用流程

### 用户下单流程

1. 用户在结账页面选择"PIX Payment"
2. 填写订单信息（包括CPF/CNPJ）
3. 提交订单
4. 系统创建PIX支付请求
5. 在订单确认页面显示PIX QR码或支付链接
6. 用户使用银行应用扫描QR码或点击链接完成支付

### 支付完成流程

1. 用户完成PIX支付
2. PIX服务器发送IPN回调到您的网站
3. 系统验证签名并更新订单状态
4. 订单状态更新为"已完成"

## 订单状态

PIX支付会更新订单状态如下：

- **pending** - 等待支付
- **processing** - 支付处理中
- **completed** - 支付成功
- **failed** - 支付失败
- **cancelled** - 支付取消

## IPN回调URL

PIX支付的IPN回调URL为：
```
https://your-site.com/wc-api/wc_pix_gateway
```

请确保：
1. 服务器可以从互联网访问
2. 使用HTTPS（生产环境）
3. 防火墙允许PIX服务器访问

## 测试

### 沙盒模式测试

1. 在网关配置中启用"Sandbox Mode"
2. 使用测试环境的API凭证
3. 进行测试支付
4. 检查订单状态是否正确更新

### 查看日志

启用调试日志后，可以在以下位置查看：
- `WooCommerce > Status > Logs`
- 选择 `pix-*.log` 文件

## 常见问题

### 1. 支付无法创建

**可能原因**:
- API凭证不正确
- 网络连接问题
- API Base URL配置错误

**解决方法**:
- 检查API凭证是否正确
- 查看调试日志
- 确认网络连接正常

### 2. IPN回调未收到

**可能原因**:
- 服务器无法从互联网访问
- 防火墙阻止了请求
- URL配置错误

**解决方法**:
- 检查服务器防火墙设置
- 确认回调URL可访问
- 查看服务器错误日志

### 3. 订单状态未更新

**可能原因**:
- IPN回调失败
- 签名验证失败
- 订单ID不匹配

**解决方法**:
- 查看调试日志
- 检查签名密钥是否正确
- 验证订单ID是否匹配

## 获取帮助

如果遇到问题：

1. 查看完整文档: `docs/PIX_INTEGRATION.md`
2. 查看架构文档: `docs/ARCHITECTURE.md`
3. 查看API文档: https://s.apifox.cn/5bba2671-7bd9-4078-9cac-5074cd3bb826?pwd=5F6R083g
4. 联系技术支持

## API文档

完整的PIX支付API文档：
- 链接: https://s.apifox.cn/5bba2671-7bd9-4078-9cac-5074cd3bb826?pwd=5F6R083g
- 密码: `5F6R083g`

---

**最后更新**: 2024-01-01

