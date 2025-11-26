# 📝 WordPress安装指南

## 安装方式

WordPress有两种安装方式：
1. **通过浏览器安装**（推荐，图形界面）
2. **使用WP-CLI命令行安装**（快速，适合自动安装）

## 方法1：通过浏览器安装（推荐）

### 步骤1：确认WordPress文件已准备好

在Ubuntu终端中运行：

```bash
sudo bash scripts/install-wordpress.sh
```

这会：
- 下载WordPress（如果还没有）
- 配置数据库连接
- 启动所有服务
- 显示访问地址

### 步骤2：访问WordPress

在Ubuntu终端中获取IP地址：

```bash
hostname -I
```

在浏览器中访问：
```
http://[IP地址]
```

### 步骤3：完成安装向导

WordPress会自动显示安装向导：

1. **选择语言**
   - 选择您喜欢的语言（中文或英文）

2. **欢迎界面**
   - 点击"现在就开始！"

3. **数据库信息**（通常已自动填充）
   - 数据库名：`wordpress`
   - 用户名：`wpuser`
   - 密码：`wppass123`
   - 数据库主机：`localhost`
   - 表前缀：`wp_`（默认）
   - 点击"提交"

4. **运行安装**
   - 点击"运行安装程序"

5. **站点信息**
   - **站点标题**：例如 "My Store"
   - **用户名**：创建管理员用户名（不要用admin）
   - **密码**：设置强密码（或使用生成的密码）
   - **邮箱**：输入您的邮箱
   - **搜索引擎可见性**：测试时建议勾选（不推荐搜索引擎索引）
   - 点击"安装WordPress"

6. **安装完成**
   - 点击"登录"按钮
   - 使用刚才设置的用户名和密码登录

### 步骤4：登录管理后台

访问：
```
http://[IP地址]/wp-admin
```

使用刚才设置的用户名和密码登录。

---

## 方法2：使用WP-CLI命令行安装（快速）

### 完整安装命令

在Ubuntu终端中运行：

```bash
cd /var/www/wordpress

# 安装WordPress（自动配置数据库）
sudo wp core install \
    --url=http://$(hostname -I | awk '{print $1}') \
    --title="My WooCommerce Store" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root
```

这会自动完成所有安装步骤，无需浏览器。

### 登录信息

- **用户名**：admin
- **密码**：admin123

**重要**：安装后请立即更改密码！

---

## 验证安装

### 检查WordPress是否已安装

```bash
cd /var/www/wordpress
sudo wp core is-installed --allow-root
```

如果返回信息，说明已安装。

### 查看站点信息

```bash
sudo wp option get siteurl --allow-root
sudo wp user list --allow-root
```

---

## 常见问题

### 问题1：无法访问WordPress

**检查服务状态**：
```bash
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status php*-fpm
```

**检查端口**：
```bash
sudo netstat -tuln | grep :80
```

**重启服务**：
```bash
sudo systemctl restart nginx mysql php*-fpm
```

### 问题2：数据库连接错误

**检查数据库**：
```bash
sudo mysql -u wpuser -pwppass123 wordpress -e "SELECT 1;"
```

**重新配置数据库**：
```bash
cd /var/www/wordpress
sudo nano wp-config.php
```

检查：
- `DB_NAME` = 'wordpress'
- `DB_USER` = 'wpuser'
- `DB_PASSWORD` = 'wppass123'
- `DB_HOST` = 'localhost'

### 问题3：权限问题

**修复权限**：
```bash
sudo chown -R www-data:www-data /var/www/wordpress
sudo chmod -R 755 /var/www/wordpress
```

### 问题4：Nginx配置问题

**检查Nginx配置**：
```bash
sudo nginx -t
```

**查看错误日志**：
```bash
sudo tail -50 /var/log/nginx/wordpress_error.log
```

---

## 安装后立即要做的事

1. **更改管理员密码**（如果使用默认密码）
2. **设置时区**：设置 > 常规 > 时区
3. **安装WooCommerce**（下一步）
4. **配置PIX支付**（再下一步）

---

## 快速安装命令

```bash
# 一键安装WordPress
cd /var/www/wordpress
sudo wp core install \
    --url=http://$(hostname -I | awk '{print $1}') \
    --title="My Store" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root

# 访问地址
echo "访问: http://$(hostname -I | awk '{print $1}')/wp-admin"
echo "用户名: admin"
echo "密码: admin123"
```

---

**推荐**: 使用方法1（浏览器安装）更直观，或者使用方法2（WP-CLI）更快速 🚀

