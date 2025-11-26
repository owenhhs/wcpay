# PIX支付测试指南

## 测试前准备

### 1. 环境检查

运行环境检查脚本：

```bash
cd /path/to/woocommerce-pay-20251122
sudo bash scripts/check-env.sh
```

### 2. 运行测试脚本

运行完整测试脚本：

```bash
sudo bash scripts/test-pix.sh
```

这会自动：
- 检查WordPress安装
- 检查WooCommerce
- 检查插件安装和激活
- 检查PIX网关配置
- 创建测试产品
- 检查货币设置

## 功能测试

### 测试1: 支付网关显示

**目标**: 验证PIX支付方式在结账页面可见

**步骤**:
1. 访问商店首页
2. 添加产品到购物车
3. 进入结账页面
4. 检查支付方式列表

**预期结果**:
- PIX Payment 出现在支付方式列表中
- 支付方式描述正确显示

**检查点**:
```bash
# 检查网关是否启用
cd /var/www/wordpress
sudo wp option get woocommerce_pix_settings --allow-root --format=json
```

### 测试2: 创建订单

**目标**: 验证可以成功创建PIX支付订单

**步骤**:
1. 在结账页面选择PIX支付
2. 填写订单信息（包括CPF）
3. 提交订单

**预期结果**:
- 订单创建成功
- 跳转到订单确认页面
- 显示PIX支付二维码或支付链接

**检查点**:
```bash
# 查看最新订单
sudo wp wc order list --allow-root --format=table --per_page=1

# 查看订单详情
sudo wp wc order get [订单ID] --allow-root
```

### 测试3: API请求

**目标**: 验证与PIX API的连接

**步骤**:
1. 运行API测试脚本
2. 检查API响应

**运行测试**:
```bash
sudo bash scripts/test-api.sh
```

**预期结果**:
- API连接成功
- 返回正确的响应格式
- 包含必要的字段（transactionId, qrCode等）

### 测试4: IPN回调

**目标**: 验证IPN回调处理

**步骤**:
1. 创建测试订单
2. 模拟IPN回调
3. 检查订单状态更新

**模拟IPN**:
```bash
# 创建测试IPN数据
cat > /tmp/test_ipn.json << 'EOF'
{
    "orderNo": "123",
    "status": "SUCCESS",
    "transactionId": "test123",
    "amount": "100.00"
}
EOF

# 生成签名（需要实际签名逻辑）
SIGNATURE="your_signature_here"

# 发送IPN
curl -X POST http://localhost/wc-api/wc_pix_gateway \
    -H "Content-Type: application/json" \
    -H "X-Signature: $SIGNATURE" \
    -d @/tmp/test_ipn.json
```

**检查点**:
- 订单状态是否正确更新
- 日志中是否有相关记录

### 测试5: 订单状态更新

**目标**: 验证不同支付状态的处理

**测试场景**:
- SUCCESS - 订单应标记为completed
- FAILED - 订单应标记为failed
- PENDING - 订单应保持pending
- CANCELLED - 订单应标记为cancelled

**检查点**:
```bash
# 查看订单状态
sudo wp wc order get [订单ID] --allow-root --field=status

# 查看订单备注
sudo wp wc order get [订单ID] --allow-root --field=status_transitions
```

## 日志检查

### WordPress调试日志

```bash
sudo tail -f /var/www/wordpress/wp-content/debug.log
```

### WooCommerce/PIX日志

```bash
# 查看PIX支付日志
sudo tail -f /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log

# 或通过后台查看
# WooCommerce > 状态 > 日志
```

### PHP错误日志

```bash
sudo tail -f /var/log/php8.1-fpm.log
```

### Nginx访问日志

```bash
sudo tail -f /var/log/nginx/wordpress_access.log
```

## 测试用例清单

### 基本功能
- [ ] 支付网关在设置页面可见
- [ ] 支付网关可以启用/禁用
- [ ] 配置项可以保存
- [ ] 支付方式在结账页面显示

### 订单创建
- [ ] 可以创建PIX支付订单
- [ ] 订单信息正确传递到API
- [ ] API返回的数据正确存储
- [ ] QR码或支付链接正确显示

### 支付处理
- [ ] IPN回调可以接收
- [ ] 签名验证正常工作
- [ ] 订单状态正确更新
- [ ] 不同支付状态正确处理

### 错误处理
- [ ] API连接失败时显示错误
- [ ] 无效凭证时显示错误
- [ ] 网络错误时正确处理
- [ ] 异常情况记录日志

### 安全测试
- [ ] 签名验证正常工作
- [ ] 无效签名被拒绝
- [ ] 敏感信息不泄露
- [ ] SQL注入防护

## 性能测试

### 响应时间

```bash
# 测试订单创建响应时间
time curl -X POST http://localhost/checkout/ \
    -d "payment_method=pix" \
    -d "billing_email=test@example.com"
```

### 并发测试

使用Apache Bench测试：

```bash
ab -n 100 -c 10 http://localhost/
```

## 回归测试

每次修改代码后，运行回归测试：

```bash
# 运行完整测试
sudo bash scripts/test-pix.sh

# 运行API测试
sudo bash scripts/test-api.sh

# 检查日志
sudo tail -100 /var/www/wordpress/wp-content/debug.log
```

## 测试报告

测试完成后，记录以下信息：

1. **测试环境**
   - WordPress版本
   - WooCommerce版本
   - PHP版本
   - 插件版本

2. **测试结果**
   - 通过的测试用例
   - 失败的测试用例
   - 发现的问题

3. **日志文件**
   - 保存测试期间的日志
   - 记录关键错误信息

4. **截图/证据**
   - 订单页面截图
   - 支付页面截图
   - 错误消息截图

## 常见问题

### 测试订单无法创建

**可能原因**:
- API凭证未配置
- 网络连接问题
- API端点错误

**解决方法**:
1. 检查API配置
2. 运行API测试脚本
3. 查看日志文件

### IPN回调不工作

**可能原因**:
- 回调URL不可访问
- 签名验证失败
- 服务器配置问题

**解决方法**:
1. 使用ngrok创建隧道
2. 检查签名算法
3. 查看服务器日志

### 订单状态不更新

**可能原因**:
- IPN回调未触发
- 订单ID不匹配
- 状态更新逻辑错误

**解决方法**:
1. 手动触发IPN测试
2. 检查订单ID映射
3. 查看代码逻辑

---

**最后更新**: 2024-01-01

