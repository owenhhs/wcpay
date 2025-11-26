# 开发环境部署指南

本文档说明如何在OrbStack的Ubuntu实例上部署WordPress + WooCommerce开发环境。

## 方案一：使用Docker Compose（推荐）

### 前置要求

- OrbStack 已安装
- Docker 可用

### 快速启动

```bash
# 进入项目目录
cd /Users/michael/Desktop/woocommerce-pay-20251122

# 使用Docker Compose启动环境
docker-compose -f scripts/docker-compose.yml up -d

# 等待服务启动（约30秒）
sleep 30

# 安装WordPress
docker exec wp-dev wp core install \
    --url=http://localhost:8080 \
    --title="WooCommerce Dev" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root

# 安装并激活WooCommerce
docker exec wp-dev wp plugin install woocommerce --activate --allow-root

# 安装Storefront主题
docker exec wp-dev wp theme install storefront --activate --allow-root

# 插件已经通过volume挂载，直接激活即可
docker exec wp-dev wp plugin activate woocommerce-pay --allow-root
```

### 访问地址

- WordPress: http://localhost:8080
- 管理后台: http://localhost:8080/wp-admin
  - 用户名: `admin`
  - 密码: `admin123`
- phpMyAdmin: http://localhost:8081
  - 服务器: `db`
  - 用户名: `wpuser`
  - 密码: `wppass123`

### 停止服务

```bash
docker-compose -f scripts/docker-compose.yml down
```

### 查看日志

```bash
# WordPress日志
docker logs wp-dev

# 数据库日志
docker logs wp-db

# 实时日志
docker-compose -f scripts/docker-compose.yml logs -f
```

## 方案二：在Ubuntu实例中直接安装

### 步骤1：进入Ubuntu实例

```bash
# 如果使用OrbStack的Ubuntu虚拟机
orbstack shell ubuntu

# 或者使用Docker容器
docker run -it --rm ubuntu:22.04 bash
```

### 步骤2：运行部署脚本

将项目文件复制到Ubuntu实例中，然后运行：

```bash
# 给脚本添加执行权限
chmod +x scripts/dev-setup.sh
chmod +x scripts/install-woocommerce.sh
chmod +x scripts/deploy-plugin.sh

# 运行主部署脚本
sudo bash scripts/dev-setup.sh

# 安装WooCommerce
sudo bash scripts/install-woocommerce.sh

# 部署插件
sudo bash scripts/deploy-plugin.sh
```

### 步骤3：完成WordPress安装

1. 访问 http://localhost（或容器映射的端口）
2. 按照向导完成WordPress安装
3. 登录管理后台

### 步骤4：配置WooCommerce

1. 进入 **WooCommerce > 设置向导**
2. 完成基本配置：
   - 商店地址
   - 货币设置（选择BRL用于PIX测试）
   - 支付方式设置
   - 运费设置

## 开发工作流

### 代码同步

#### Docker Compose方式

代码已经通过volume挂载，修改代码后立即生效：

```bash
# 代码已在容器中，修改本地文件即可
# 如需重启服务
docker-compose -f scripts/docker-compose.yml restart wordpress
```

#### 直接安装方式

每次修改代码后，重新部署插件：

```bash
sudo bash scripts/deploy-plugin.sh
```

### 调试

#### 启用WordPress调试

编辑 `wp-config.php`:

```php
define('WP_DEBUG', true);
define('WP_DEBUG_LOG', true);
define('WP_DEBUG_DISPLAY', false);
@ini_set('display_errors', 0);
```

日志文件位置：
- `/var/www/wordpress/wp-content/debug.log`

#### 查看WooCommerce日志

1. 进入 **WooCommerce > 状态 > 日志**
2. 选择相应的日志文件查看

#### 查看Nginx日志

```bash
# 访问日志
tail -f /var/log/nginx/wordpress_access.log

# 错误日志
tail -f /var/log/nginx/wordpress_error.log
```

#### 查看PHP错误日志

```bash
# PHP-FPM错误日志
tail -f /var/log/php8.1-fpm.log

# 或查看系统日志
tail -f /var/log/syslog | grep php
```

### 测试PIX支付

#### 1. 配置PIX网关

1. 进入 **WooCommerce > 设置 > 支付**
2. 点击 **PIX Payment** 进行配置
3. 填写API凭证（沙盒模式）

#### 2. 创建测试订单

1. 添加测试产品
2. 进入结账页面
3. 选择PIX支付方式
4. 完成订单

#### 3. 查看日志

```bash
# 查看插件日志
tail -f /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log

# 或通过WordPress后台查看
# WooCommerce > 状态 > 日志
```

## 常见问题

### 1. 端口被占用

如果8080端口被占用，修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "8080:80"  # 改为其他端口，如 "9000:80"
```

### 2. 权限问题

如果遇到权限问题：

```bash
# Docker方式
docker exec wp-dev chown -R www-data:www-data /var/www/html

# 直接安装方式
sudo chown -R www-data:www-data /var/www/wordpress
```

### 3. 插件无法激活

检查插件文件是否正确复制：

```bash
# Docker方式
docker exec wp-dev ls -la /var/www/html/wp-content/plugins/woocommerce-pay

# 直接安装方式
ls -la /var/www/wordpress/wp-content/plugins/woocommerce-pay
```

### 4. 数据库连接失败

检查数据库服务是否运行：

```bash
# Docker方式
docker exec wp-db mysql -u wpuser -pwppass123 wordpress -e "SELECT 1;"

# 直接安装方式
sudo systemctl status mysql
mysql -u wpuser -pwppass123 wordpress -e "SELECT 1;"
```

### 5. IPN回调无法接收

开发环境通常无法从外部接收IPN回调，可以使用：

1. **ngrok** 创建隧道：
   ```bash
   ngrok http 8080
   ```

2. 使用返回的URL配置IPN回调地址

3. 或在本地测试时，手动触发订单状态更新

## 快速命令参考

### Docker方式

```bash
# 进入WordPress容器
docker exec -it wp-dev bash

# 运行WP-CLI命令
docker exec wp-dev wp plugin list --allow-root

# 查看插件状态
docker exec wp-dev wp plugin status woocommerce-pay --allow-root

# 重启服务
docker-compose -f scripts/docker-compose.yml restart

# 停止服务
docker-compose -f scripts/docker-compose.yml stop

# 启动服务
docker-compose -f scripts/docker-compose.yml start

# 完全删除（包括数据）
docker-compose -f scripts/docker-compose.yml down -v
```

### 直接安装方式

```bash
# 重启服务
sudo systemctl restart nginx mysql php8.1-fpm

# 查看服务状态
sudo systemctl status nginx mysql php8.1-fpm

# 重新部署插件
sudo bash scripts/deploy-plugin.sh

# 查看WordPress日志
tail -f /var/www/wordpress/wp-content/debug.log
```

## 下一步

环境部署完成后：

1. ✅ 配置PIX支付网关
2. ✅ 测试支付流程
3. ✅ 查看日志调试问题
4. ✅ 开发新功能

---

**最后更新**: 2024-01-01

