# OrbStack Ubuntu 开发环境设置指南

本指南说明如何在OrbStack的Ubuntu实例中手动设置WordPress开发环境。

## 前置准备

### 1. 启动Ubuntu实例

```bash
# 方法1: 使用OrbStack UI启动Ubuntu虚拟机

# 方法2: 使用命令行
orbstack shell ubuntu
```

### 2. 安装基础工具

```bash
# 更新系统
sudo apt-get update
sudo apt-get upgrade -y

# 安装必要工具
sudo apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    unzip
```

## 方案A: 使用Docker（如果网络可用）

### 步骤1: 安装Docker

```bash
# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 重新登录以使Docker组权限生效
# 或运行: newgrp docker
```

### 步骤2: 启动环境

```bash
# 进入项目目录
cd /path/to/woocommerce-pay-20251122

# 启动Docker环境
docker-compose -f scripts/docker-compose.yml up -d

# 等待服务启动
sleep 30

# 安装WordPress
docker exec wp-dev wp core install \
    --url=http://localhost:8080 \
    --title="WooCommerce Dev" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root

# 安装WooCommerce
docker exec wp-dev wp plugin install woocommerce --activate --allow-root
docker exec wp-dev wp theme install storefront --activate --allow-root
docker exec wp-dev wp plugin activate woocommerce-pay --allow-root
```

### 步骤3: 访问

- WordPress: http://localhost:8080
- 管理后台: http://localhost:8080/wp-admin (admin/admin123)

## 方案B: 本地安装（推荐，离线可用）

### 步骤1: 复制项目文件到Ubuntu

如果项目在宿主机上，需要复制到Ubuntu实例：

```bash
# 在宿主机上（Mac）
# 方式1: 使用共享文件夹（如果OrbStack支持）

# 方式2: 使用SCP/rsync
# 先确定Ubuntu的IP地址

# 方式3: 使用git clone（如果有网络）
git clone <your-repo-url>

# 方式4: 压缩后传输
# 在Mac上：
tar -czf woocommerce-pay.tar.gz woocommerce-pay-20251122
# 然后通过OrbStack的文件共享功能复制
```

### 步骤2: 运行安装脚本

```bash
# 进入项目目录
cd /path/to/woocommerce-pay-20251122

# 给脚本执行权限
chmod +x scripts/*.sh

# 运行主安装脚本
sudo bash scripts/dev-setup.sh

# 安装WooCommerce
sudo bash scripts/install-woocommerce.sh

# 部署插件
sudo bash scripts/deploy-plugin.sh
```

### 步骤3: 访问WordPress

1. 确定WordPress访问地址：
   ```bash
   # 查看IP地址
   hostname -I
   # 或
   ip addr show
   ```

2. 访问 http://[IP地址] 或 http://localhost

3. 完成WordPress安装向导

4. 登录管理后台并配置WooCommerce

## 方案C: 使用现有WordPress安装

如果Ubuntu实例已有WordPress：

### 步骤1: 部署插件

```bash
# 复制插件到WordPress插件目录
sudo cp -r woocommerce-pay-20251122 /var/www/wordpress/wp-content/plugins/woocommerce-pay

# 设置权限
sudo chown -R www-data:www-data /var/www/wordpress/wp-content/plugins/woocommerce-pay
sudo chmod -R 755 /var/www/wordpress/wp-content/plugins/woocommerce-pay
```

### 步骤2: 激活插件

1. 登录WordPress管理后台
2. 进入 **插件 > 已安装的插件**
3. 找到 **woocommerce-pay** 插件
4. 点击 **启用**

### 步骤3: 使用WP-CLI激活

```bash
cd /var/www/wordpress
wp plugin activate woocommerce-pay --allow-root
```

## 配置开发环境

### 启用调试模式

编辑 `wp-config.php`:

```bash
sudo nano /var/www/wordpress/wp-config.php
```

添加以下内容：

```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
@ini_set('display_errors', 0);
```

### 设置文件权限

```bash
# 设置WordPress目录权限
sudo chown -R www-data:www-data /var/www/wordpress
sudo find /var/www/wordpress -type d -exec chmod 755 {} \;
sudo find /var/www/wordpress -type f -exec chmod 644 {} \;
```

### 配置虚拟主机（如果需要）

如果需要从宿主机访问Ubuntu中的WordPress：

1. **端口转发**: 在OrbStack中配置端口转发
   - 将Ubuntu的80端口映射到宿主机的8080端口

2. **或使用Nginx反向代理**: 配置Nginx代理到WordPress

## 开始调试

### 1. 配置PIX支付网关

1. 登录WordPress后台
2. 进入 **WooCommerce > 设置 > 支付**
3. 点击 **PIX Payment**
4. 配置以下信息：
   - 启用PIX支付
   - API Base URL: （从API文档获取）
   - App ID: （从API文档获取）
   - Sign Key: （从API文档获取）
   - 启用沙盒模式（测试时）
   - 启用调试日志

### 2. 测试支付流程

1. **创建测试产品**:
   - 进入 **产品 > 添加新产品**
   - 创建简单产品，设置价格（BRL货币）

2. **测试结账**:
   - 访问商店首页
   - 添加产品到购物车
   - 进入结账页面
   - 选择PIX支付方式
   - 填写订单信息（包括CPF）
   - 提交订单

3. **查看订单**:
   - 进入 **WooCommerce > 订单**
   - 查看订单状态

### 3. 查看日志

#### WordPress调试日志

```bash
tail -f /var/www/wordpress/wp-content/debug.log
```

#### WooCommerce日志

```bash
# 通过后台查看
# WooCommerce > 状态 > 日志

# 或直接查看文件
tail -f /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log
```

#### PHP错误日志

```bash
tail -f /var/log/php8.1-fpm.log
# 或
tail -f /var/log/syslog | grep php
```

#### Nginx日志

```bash
tail -f /var/log/nginx/wordpress_error.log
tail -f /var/log/nginx/wordpress_access.log
```

## 常用开发命令

### WP-CLI命令

```bash
cd /var/www/wordpress

# 查看插件列表
wp plugin list --allow-root

# 激活/停用插件
wp plugin activate woocommerce-pay --allow-root
wp plugin deactivate woocommerce-pay --allow-root

# 查看插件状态
wp plugin status woocommerce-pay --allow-root

# 清空缓存（如果使用缓存插件）
wp cache flush --allow-root

# 重置数据库（谨慎使用）
# wp db reset --yes --allow-root
```

### 服务管理

```bash
# 重启服务
sudo systemctl restart nginx
sudo systemctl restart mysql
sudo systemctl restart php8.1-fpm

# 查看服务状态
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status php8.1-fpm

# 查看所有服务
sudo systemctl list-units --type=service --state=running
```

### 文件操作

```bash
# 重新部署插件
cd /path/to/woocommerce-pay-20251122
sudo bash scripts/deploy-plugin.sh

# 手动复制插件文件
sudo cp -r /path/to/source /var/www/wordpress/wp-content/plugins/woocommerce-pay
sudo chown -R www-data:www-data /var/www/wordpress/wp-content/plugins/woocommerce-pay
```

## 故障排查

### 插件无法激活

1. 检查PHP版本：
   ```bash
   php -v
   ```
   需要PHP 7.2+

2. 检查文件权限：
   ```bash
   ls -la /var/www/wordpress/wp-content/plugins/woocommerce-pay
   ```

3. 查看PHP错误：
   ```bash
   tail -f /var/log/php8.1-fpm.log
   ```

### 支付网关不显示

1. 检查货币设置：
   - WooCommerce > 设置 > 常规
   - 货币选择：巴西雷亚尔 (BRL)

2. 检查API凭证是否填写

3. 查看调试日志

### IPN回调无法接收

开发环境通常无法接收外部回调，可以：

1. **使用ngrok创建隧道**:
   ```bash
   # 安装ngrok
   wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
   tar xvzf ngrok-v3-stable-linux-amd64.tgz
   sudo mv ngrok /usr/local/bin/
   
   # 创建隧道
   ngrok http 80
   ```

2. **使用回调URL**: 将ngrok提供的URL配置为IPN回调地址

3. **手动测试**: 使用Postman等工具模拟IPN回调

## 下一步

环境配置完成后：

1. ✅ 配置PIX支付网关
2. ✅ 创建测试订单
3. ✅ 测试支付流程
4. ✅ 查看日志调试
5. ✅ 开发新功能

---

**提示**: 如果遇到网络问题无法下载Docker镜像，使用方案B（本地安装）更可靠。

**最后更新**: 2024-01-01

