# 调试环境快速开始

## 🚀 在OrbStack中开始调试

### 第一步：进入Ubuntu环境

```bash
orbstack shell ubuntu
```

如果没有Ubuntu实例，先在OrbStack UI中创建一个。

### 第二步：复制项目文件

**方式1: 通过共享文件夹（如果OrbStack支持）**
```bash
cd /mnt/Users/michael/Desktop/woocommerce-pay-20251122
# 或尝试
cd /host/Users/michael/Desktop/woocommerce-pay-20251122
```

**方式2: 使用git克隆**
```bash
cd ~
git clone https://github.com/owenhhs/wcpay.git
cd wcpay
```

**方式3: 手动复制（在Mac终端）**
```bash
# 在Mac上打包
cd /Users/michael/Desktop
tar -czf woocommerce-pay.tar.gz woocommerce-pay-20251122/

# 然后通过OrbStack文件共享或其他方式复制到Ubuntu
```

### 第三步：一键设置环境

```bash
# 进入项目目录
cd woocommerce-pay-20251122

# 给脚本执行权限
chmod +x scripts/*.sh

# 运行环境设置（会自动安装WordPress、Nginx、MySQL、PHP）
sudo bash scripts/setup-orbstack.sh
```

### 第四步：安装WooCommerce

```bash
sudo bash scripts/install-woocommerce.sh
```

### 第五步：部署支付插件

```bash
sudo bash scripts/deploy-plugin.sh
```

### 第六步：访问WordPress

```bash
# 获取Ubuntu的IP地址
hostname -I

# 在浏览器中访问（使用上面获取的IP）
# http://[IP地址]
```

或者配置端口转发后访问：`http://localhost:8080`

完成WordPress安装向导，创建管理员账户。

### 第七步：配置PIX支付

1. 登录管理后台：`http://[IP]/wp-admin`
2. 进入 **WooCommerce > 设置 > 支付**
3. 点击 **PIX Payment**
4. 配置：
   - ✓ 启用PIX支付
   - API Base URL: （从API文档获取）
   - App ID: （从API文档获取）
   - Sign Key: （从API文档获取）
   - ✓ 启用沙盒模式（测试时）
   - ✓ 启用调试日志

### 第八步：开始调试

#### 创建测试订单

```bash
# 使用WP-CLI创建测试产品
cd /var/www/wordpress
sudo wp wc product create \
    --name="测试产品" \
    --type=simple \
    --regular_price=100.00 \
    --allow-root
```

或通过后台：**产品 > 添加新产品**

#### 测试支付流程

1. 访问商店首页
2. 添加产品到购物车
3. 进入结账页面
4. 选择PIX支付方式
5. 提交订单

#### 查看日志

```bash
# WordPress调试日志
sudo tail -f /var/www/wordpress/wp-content/debug.log

# WooCommerce/PIX支付日志
sudo tail -f /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log

# PHP错误日志
sudo tail -f /var/log/php8.1-fpm.log

# Nginx错误日志
sudo tail -f /var/log/nginx/wordpress_error.log

# 同时查看多个日志
sudo tail -f \
  /var/www/wordpress/wp-content/debug.log \
  /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log \
  /var/log/php8.1-fpm.log
```

## 📋 常用调试命令

### 检查环境

```bash
# 检查服务状态
sudo systemctl status nginx mysql php8.1-fpm

# 检查PHP版本
php -v

# 检查插件是否激活
cd /var/www/wordpress
sudo wp plugin list --allow-root
sudo wp plugin status woocommerce-pay --allow-root
```

### 重启服务

```bash
sudo systemctl restart nginx
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm

# 或全部重启
sudo systemctl restart nginx mysql php8.1-fpm
```

### 重新部署插件

```bash
cd /path/to/woocommerce-pay-20251122
sudo bash scripts/deploy-plugin.sh
```

### 编辑代码并测试

```bash
# 编辑插件文件
sudo nano /var/www/wordpress/wp-content/plugins/woocommerce-pay/includes/class-wc-pix-gateway.php

# 修改后重启PHP-FPM使更改生效
sudo systemctl restart php8.1-fpm

# 实时查看错误
sudo tail -f /var/log/php8.1-fpm.log
```

## 🔍 调试技巧

### 1. 启用详细日志

编辑 `/var/www/wordpress/wp-config.php`：

```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
define('SCRIPT_DEBUG', true);
```

### 2. 查看数据库

```bash
# 使用mysql命令行
sudo mysql -u wpuser -pwppass123 wordpress

# 查看订单表
SELECT * FROM wp_posts WHERE post_type = 'shop_order' ORDER BY post_date DESC LIMIT 10;

# 查看订单meta
SELECT * FROM wp_postmeta WHERE post_id = [订单ID];
```

### 3. 测试API连接

```bash
# 测试API端点（替换为实际URL）
curl -X POST https://api.example.com/payment/create \
  -H "Content-Type: application/json" \
  -H "Authorization: Basic [base64编码的app_id:sign_key]" \
  -d '{"test": "data"}'
```

### 4. 模拟IPN回调

```bash
# 创建测试IPN数据
cat > /tmp/test_ipn.json << 'EOF'
{
    "orderNo": "123",
    "status": "SUCCESS",
    "transactionId": "test123"
}
EOF

# 发送到IPN端点
curl -X POST http://localhost/wc-api/wc_pix_gateway \
  -H "Content-Type: application/json" \
  -H "X-Signature: [签名]" \
  -d @/tmp/test_ipn.json
```

## 📚 文档索引

- **完整设置指南**: `docs/DEV_SETUP.md`
- **OrbStack详细指南**: `scripts/orbstack-guide.md`
- **调试检查清单**: `scripts/debug-checklist.md`
- **PIX集成文档**: `docs/PIX_INTEGRATION.md`
- **快速开始**: `docs/PIX_QUICKSTART.md`

## ⚠️ 常见问题

### 无法访问WordPress

1. 检查Nginx状态：`sudo systemctl status nginx`
2. 检查端口：`sudo netstat -tuln | grep 80`
3. 查看Nginx错误：`sudo tail -50 /var/log/nginx/wordpress_error.log`

### 插件无法激活

1. 检查PHP版本：`php -v` （需要 >= 7.2）
2. 检查文件权限：`ls -la /var/www/wordpress/wp-content/plugins/woocommerce-pay`
3. 查看PHP错误：`sudo tail -50 /var/log/php8.1-fpm.log`

### 支付网关不显示

1. 确认货币设置为BRL
2. 确认API凭证已填写
3. 查看调试日志

### IPN回调无法接收

开发环境通常无法接收外部回调，可以：

1. 使用ngrok创建隧道
2. 或手动触发订单状态更新进行测试

## 🎯 下一步

环境配置完成后：

1. ✅ 配置PIX支付网关
2. ✅ 创建测试订单
3. ✅ 测试支付流程
4. ✅ 查看日志调试
5. ✅ 开发新功能

---

**提示**: 遇到问题？查看 `scripts/debug-checklist.md` 逐项检查。

