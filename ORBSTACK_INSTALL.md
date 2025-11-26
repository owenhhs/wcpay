# 🚀 OrbStack Ubuntu完整安装指南

## 当前状态

环境检查显示所有组件都未安装。现在开始一键安装所有组件。

## ✅ 一键完整安装（推荐）

在Ubuntu终端中，**确保您在项目目录** (`~/wcpay`)，然后运行：

```bash
cd ~/wcpay
chmod +x scripts/*.sh
sudo bash scripts/install-all-complete.sh
```

这会自动安装：
- ✅ PHP 8.1
- ✅ MySQL
- ✅ Nginx
- ✅ WordPress
- ✅ WP-CLI
- ✅ WooCommerce
- ✅ 支付插件

**预计时间：10-15分钟**

## 📋 分步安装

如果想分步安装：

### 步骤1: 安装基础环境

```bash
cd ~/wcpay
sudo bash scripts/install-all.sh
```

这会安装：PHP、MySQL、Nginx、WordPress

### 步骤2: 安装WooCommerce

```bash
sudo bash scripts/install-woocommerce.sh
```

### 步骤3: 部署插件

```bash
sudo bash scripts/deploy-plugin.sh
```

## 🎯 安装完成后的步骤

### 1. 获取IP地址

```bash
hostname -I
```

### 2. 访问WordPress

在浏览器中访问：
```
http://[IP地址]
```

### 3. 完成WordPress安装

按照向导完成：
- 网站标题
- 管理员用户名
- 管理员密码  
- 邮箱地址

### 4. 配置WooCommerce

登录后台后：
- 进入 **WooCommerce > 设置向导**
- 完成基本配置
- **重要**：货币选择 **BRL**（巴西雷亚尔）

### 5. 配置PIX支付

- 进入 **WooCommerce > 设置 > 支付**
- 点击 **PIX Payment**
- 填写API凭证：
  - API Base URL
  - App ID
  - Sign Key
- 启用沙盒模式（测试时）
- 启用调试日志
- 保存更改

### 6. 运行测试

```bash
cd ~/wcpay
sudo bash scripts/test-pix.sh
```

## 📊 安装进度说明

安装脚本会显示进度：

```
[1/8] 更新系统包
[2/8] 安装基础工具
[3/8] 添加PHP仓库并安装PHP 8.1
[4/8] 安装MySQL
[5/8] 安装Nginx
[6/8] 下载并配置WordPress
[7/8] 配置Nginx
[8/8] 安装WP-CLI和启动服务
```

## ⚠️ 注意事项

1. **需要sudo权限**，可能需要输入密码
2. **确保网络连接正常**（需要下载软件包和WordPress）
3. **安装需要10-15分钟**，请耐心等待
4. 如果下载WordPress失败，脚本会尝试使用镜像源

## 🔍 验证安装

安装完成后，可以运行：

```bash
# 检查PHP
php -v

# 检查MySQL
sudo systemctl status mysql

# 检查Nginx
sudo systemctl status nginx

# 检查WordPress
ls -la /var/www/wordpress
```

## 🆘 常见问题

### 问题1: WordPress下载失败

如果下载失败，脚本会尝试使用中文镜像源。如果还是失败：

```bash
# 手动下载WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz -C /var/www/
sudo mv /var/www/wordpress /var/www/wordpress_old 2>/dev/null
sudo mv /tmp/wordpress /var/www/wordpress
sudo chown -R www-data:www-data /var/www/wordpress
```

### 问题2: MySQL启动失败

```bash
# 检查MySQL状态
sudo systemctl status mysql

# 启动MySQL
sudo systemctl start mysql

# 查看MySQL日志
sudo tail -50 /var/log/mysql/error.log
```

### 问题3: Nginx启动失败

```bash
# 检查Nginx配置
sudo nginx -t

# 查看Nginx错误日志
sudo tail -50 /var/log/nginx/error.log
```

### 问题4: 端口80被占用

```bash
# 查看占用端口的进程
sudo lsof -i :80
# 或
sudo netstat -tulpn | grep :80

# 停止占用端口的服务
sudo systemctl stop apache2  # 如果有Apache
```

## 📝 快速命令参考

```bash
# 一键完整安装
cd ~/wcpay && sudo bash scripts/install-all-complete.sh

# 检查安装状态
sudo bash scripts/check-env.sh

# 运行测试
sudo bash scripts/test-pix.sh

# 查看日志
sudo tail -f /var/www/wordpress/wp-content/debug.log
```

---

**现在就开始**: 运行 `sudo bash scripts/install-all-complete.sh` 🚀

