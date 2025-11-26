# 🔧 修复PHP安装问题

## 问题

Ubuntu 25.10 不支持 ondrej/php PPA仓库，出现错误：
```
E: The repository 'https://ppa.launchpadcontent.net/ondrej/php/ubuntu questing Release' does not have a Release file.
```

## ✅ 解决方案

### 方法1: 使用修复版脚本（推荐）

在Ubuntu终端中运行：

```bash
cd ~/wcpay
git pull origin main
chmod +x scripts/*.sh
sudo bash scripts/install-all-fixed.sh
```

### 方法2: 手动安装PHP（如果脚本还有问题）

```bash
# 更新系统
sudo apt-get update

# 安装系统默认PHP（Ubuntu 25.10自带PHP 8.3或8.4）
sudo apt-get install -y \
    php \
    php-cli \
    php-fpm \
    php-mysql \
    php-xml \
    php-mbstring \
    php-curl \
    php-zip \
    php-gd \
    php-intl \
    php-opcache

# 检查PHP版本
php -v

# 检查PHP-FPM服务
systemctl status php*-fpm
```

### 方法3: 移除有问题的PPA并继续

如果之前的安装尝试添加了PPA，先移除：

```bash
# 移除PPA
sudo add-apt-repository --remove ppa:ondrej/php
sudo apt-get update

# 然后使用系统PHP
sudo apt-get install -y php php-fpm php-mysql php-xml php-mbstring php-curl php-zip php-gd php-intl
```

## 🔍 检查安装

安装后检查：

```bash
# 检查PHP版本
php -v

# 检查PHP-FPM服务
systemctl list-units --type=service | grep php

# 检查PHP-FPM socket
ls -la /var/run/php/

# 查看PHP配置
php --ini
```

## 📝 Nginx配置

如果使用系统默认PHP，Nginx配置中的PHP-FPM socket路径可能是：

- `/var/run/php/php-fpm.sock` (通用)
- `/var/run/php/php8.3-fpm.sock` (PHP 8.3)
- `/var/run/php/php8.4-fpm.sock` (PHP 8.4)

修复版脚本会自动检测并使用正确的路径。

## 🚀 继续安装

PHP安装完成后，继续：

```bash
# 安装MySQL
sudo apt-get install -y mysql-server mysql-client

# 安装Nginx
sudo apt-get install -y nginx

# 然后继续WordPress安装...
```

---

**推荐**: 使用修复版脚本 `sudo bash scripts/install-all-fixed.sh` 🚀

