# 🧪 开始测试

## 快速开始测试流程

### 方案A: 如果环境已准备好

直接在Ubuntu环境中运行：

```bash
# 1. 进入Ubuntu环境
orbstack shell ubuntu

# 2. 进入项目目录
cd /path/to/woocommerce-pay-20251122

# 3. 运行完整测试
sudo bash scripts/test-pix.sh
```

### 方案B: 如果环境未准备好

先设置环境，再测试：

```bash
# 1. 进入Ubuntu环境
orbstack shell ubuntu

# 2. 进入项目目录
cd /path/to/woocommerce-pay-20251122

# 3. 设置环境（首次运行）
sudo bash scripts/setup-orbstack.sh
sudo bash scripts/install-woocommerce.sh
sudo bash scripts/deploy-plugin.sh

# 4. 运行测试
sudo bash scripts/test-pix.sh
```

## 📋 测试步骤

### 步骤1: 环境检查

```bash
sudo bash scripts/check-env.sh
```

检查结果应该显示：
- ✓ WordPress已安装
- ✓ WooCommerce已安装
- ✓ 支付插件已安装

### 步骤2: 功能测试

```bash
sudo bash scripts/test-pix.sh
```

这会自动：
1. 检查WordPress和WooCommerce
2. 检查插件安装和激活
3. 创建测试产品
4. 检查配置

### 步骤3: API测试（需要API凭证）

```bash
sudo bash scripts/test-api.sh
```

测试与PIX API的连接。

### 步骤4: 手动测试流程

#### 4.1 访问WordPress

```bash
# 获取IP地址
hostname -I

# 访问: http://[IP地址]
```

#### 4.2 配置PIX支付

1. 登录管理后台: `http://[IP]/wp-admin`
2. 进入 **WooCommerce > 设置 > 支付**
3. 点击 **PIX Payment**
4. 配置：
   - ✓ 启用PIX支付
   - API Base URL: （从API文档获取）
   - App ID: （从API文档获取）
   - Sign Key: （从API文档获取）
   - ✓ 启用沙盒模式
   - ✓ 启用调试日志
5. 保存更改

#### 4.3 创建测试订单

1. 访问商店首页
2. 点击测试产品
3. 添加到购物车
4. 进入结账页面
5. 填写订单信息：
   - 姓名
   - 邮箱
   - 电话
   - CPF/CNPJ
   - 地址
6. 选择 **PIX Payment** 支付方式
7. 提交订单

#### 4.4 验证订单

检查订单是否创建：
```bash
cd /var/www/wordpress
sudo wp wc order list --allow-root --format=table
```

查看订单详情：
```bash
sudo wp wc order get [订单ID] --allow-root
```

#### 4.5 查看日志

实时查看日志：
```bash
# WordPress调试日志
sudo tail -f /var/www/wordpress/wp-content/debug.log

# PIX支付日志
sudo tail -f /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log

# PHP错误日志
sudo tail -f /var/log/php8.1-fpm.log
```

## 🔍 测试检查清单

### 基础功能
- [ ] WordPress正常运行
- [ ] WooCommerce已安装并激活
- [ ] 支付插件已安装并激活
- [ ] PIX网关在设置页面可见
- [ ] PIX网关可以启用

### 支付流程
- [ ] 支付方式在结账页面显示
- [ ] 可以选择PIX支付方式
- [ ] 可以创建PIX支付订单
- [ ] 订单页面显示QR码或支付链接
- [ ] 订单状态正确更新

### API集成
- [ ] API连接测试通过
- [ ] 可以创建支付请求
- [ ] 收到正确的API响应
- [ ] QR码/支付链接正确显示

### IPN回调
- [ ] IPN回调URL可访问
- [ ] 签名验证正常工作
- [ ] 订单状态正确更新
- [ ] 日志正确记录

### 错误处理
- [ ] API错误正确显示
- [ ] 网络错误正确处理
- [ ] 无效数据正确验证
- [ ] 错误日志正确记录

## 🐛 调试技巧

### 查看实时日志

```bash
# 同时查看多个日志文件
sudo tail -f \
  /var/www/wordpress/wp-content/debug.log \
  /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log \
  /var/log/php8.1-fpm.log \
  /var/log/nginx/wordpress_error.log
```

### 检查插件状态

```bash
cd /var/www/wordpress
sudo wp plugin list --allow-root
sudo wp plugin status woocommerce-pay --allow-root
```

### 检查订单

```bash
# 列出所有订单
sudo wp wc order list --allow-root

# 查看最新订单
sudo wp wc order list --allow-root --format=table --per_page=5

# 查看订单详情
sudo wp wc order get [订单ID] --allow-root
```

### 检查配置

```bash
# 查看PIX网关配置
sudo wp option get woocommerce_pix_settings --allow-root --format=json | python3 -m json.tool

# 查看货币设置
sudo wp option get woocommerce_currency --allow-root
```

## 📊 测试报告模板

完成测试后，记录以下信息：

### 测试环境
- WordPress版本: _______
- WooCommerce版本: _______
- PHP版本: _______
- 插件版本: _______

### 测试结果
- 测试日期: _______
- 测试人员: _______
- 通过测试: ___ / ___
- 失败测试: ___ / ___

### 问题记录
1. 问题描述: _______
   解决状态: _______
   
2. 问题描述: _______
   解决状态: _______

### 日志文件
- 调试日志位置: _______
- 支付日志位置: _______

## 🚀 快速测试命令

```bash
# 一键运行所有测试
sudo bash scripts/test-pix.sh && sudo bash scripts/test-api.sh

# 查看所有日志
sudo tail -f /var/www/wordpress/wp-content/debug.log \
            /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log

# 重启服务
sudo systemctl restart nginx mysql php8.1-fpm

# 重新部署插件
sudo bash scripts/deploy-plugin.sh
```

## 📚 相关文档

- **完整测试指南**: `docs/TESTING.md`
- **调试快速开始**: `README_DEBUG.md`
- **PIX集成文档**: `docs/PIX_INTEGRATION.md`
- **调试检查清单**: `scripts/debug-checklist.md`

---

**开始测试**: 运行 `sudo bash scripts/test-pix.sh` 🚀

