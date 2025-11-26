# OrbStack环境调试指南

## 快速开始

### 步骤1: 进入OrbStack Ubuntu环境

在终端中运行：
```bash
orbstack shell ubuntu
```

如果没有Ubuntu实例，先创建一个：
- 打开OrbStack应用
- 创建新的Ubuntu 22.04实例
- 或使用命令行：`orbstack create ubuntu`

### 步骤2: 复制项目文件到Ubuntu

有几种方式：

**方式1: 使用git（如果有网络）**
```bash
# 在Ubuntu中
cd ~
git clone <your-repo-url>
# 或
git clone https://github.com/owenhhs/wcpay.git
cd wcpay
```

**方式2: 使用文件共享（推荐）**
```bash
# OrbStack支持文件共享，直接访问Mac的文件
# 通常在 /mnt/ 或 /host/ 目录下
ls /mnt/
# 或
ls /host/Users/michael/Desktop/
```

**方式3: 使用SCP从Mac复制**
```bash
# 在Mac终端中
cd /Users/michael/Desktop/woocommerce-pay-20251122
tar -czf woocommerce-pay.tar.gz .
# 然后通过OrbStack的端口转发或共享文件夹复制
```

### 步骤3: 运行环境设置脚本

```bash
# 进入项目目录
cd /path/to/woocommerce-pay-20251122

# 给脚本执行权限
chmod +x scripts/*.sh

# 运行主设置脚本
sudo bash scripts/setup-orbstack.sh
```

### 步骤4: 安装WooCommerce

```bash
sudo bash scripts/install-woocommerce.sh
```

### 步骤5: 部署插件

```bash
sudo bash scripts/deploy-plugin.sh
```

### 步骤6: 访问WordPress

1. 获取Ubuntu的IP地址：
   ```bash
   hostname -I
   ```

2. 在浏览器中访问：
   - http://[IP地址]
   - 或配置端口转发后访问 http://localhost

3. 完成WordPress安装向导

4. 登录管理后台并配置WooCommerce

## 调试步骤

### 1. 配置PIX支付网关

1. 登录WordPress后台: http://[IP]/wp-admin
2. 进入 **WooCommerce > 设置 > 支付**
3. 点击 **PIX Payment**
4. 填写配置：
   - 启用PIX支付: ✓
   - API Base URL: (从API文档获取)
   - App ID: (从API文档获取)
   - Sign Key: (从API文档获取)
   - 沙盒模式: 启用（测试时）
   - 调试日志: 启用

### 2. 创建测试订单

```bash
# 使用WP-CLI创建测试产品
cd /var/www/wordpress
sudo wp wc product create \
    --name="测试产品" \
    --type=simple \
    --regular_price=100.00 \
    --allow-root
```

或通过后台：
1. 进入 **产品 > 添加新产品**
2. 创建简单产品
3. 设置价格（BRL货币）

### 3. 测试支付流程

1. 访问商店首页
2. 添加产品到购物车
3. 进入结账页面
4. 选择PIX支付方式
5. 填写订单信息
6. 提交订单

### 4. 查看日志

#### WordPress调试日志
```bash
sudo tail -f /var/www/wordpress/wp-content/debug.log
```

#### WooCommerce日志
```bash
# 通过后台查看
# WooCommerce > 状态 > 日志

# 或直接查看文件
sudo tail -f /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log
```

#### PHP错误日志
```bash
sudo tail -f /var/log/php8.1-fpm.log
```

#### Nginx日志
```bash
sudo tail -f /var/log/nginx/wordpress_error.log
sudo tail -f /var/log/nginx/wordpress_access.log
```

### 5. 实时调试

```bash
# 查看实时错误
sudo tail -f /var/www/wordpress/wp-content/debug.log \
            /var/log/php8.1-fpm.log \
            /var/log/nginx/wordpress_error.log

# 查看插件文件
sudo nano /var/www/wordpress/wp-content/plugins/woocommerce-pay/includes/class-wc-pix-gateway.php

# 修改后重启PHP-FPM
sudo systemctl restart php8.1-fpm
```

## 端口转发配置

为了从Mac访问Ubuntu中的WordPress：

1. 在OrbStack UI中：
   - 选择Ubuntu实例
   - 点击"Ports"或"网络"设置
   - 添加端口映射：80 -> 8080

2. 然后可以访问：
   - http://localhost:8080

## 常用命令

```bash
# 重启服务
sudo systemctl restart nginx
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm

# 查看服务状态
sudo systemctl status nginx mysql php8.1-fpm

# 重新部署插件
cd /path/to/woocommerce-pay-20251122
sudo bash scripts/deploy-plugin.sh

# 使用WP-CLI
cd /var/www/wordpress
sudo wp plugin list --allow-root
sudo wp plugin activate woocommerce-pay --allow-root
sudo wp option get siteurl --allow-root
```

## 故障排查

### 插件无法激活
```bash
# 检查PHP版本
php -v

# 检查文件权限
ls -la /var/www/wordpress/wp-content/plugins/woocommerce-pay

# 查看PHP错误
sudo tail -50 /var/log/php8.1-fpm.log
```

### 数据库连接失败
```bash
# 测试数据库连接
sudo mysql -u wpuser -pwppass123 wordpress -e "SELECT 1;"

# 检查MySQL状态
sudo systemctl status mysql
```

### 无法访问WordPress
```bash
# 检查Nginx状态
sudo systemctl status nginx

# 检查端口
sudo netstat -tuln | grep 80

# 查看Nginx错误
sudo tail -50 /var/log/nginx/wordpress_error.log
```

