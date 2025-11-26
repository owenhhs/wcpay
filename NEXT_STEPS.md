# 🎯 安装完成后的下一步

## 第一步：访问WordPress并完成安装

### 1.1 获取IP地址

在Ubuntu终端中运行：

```bash
hostname -I
```

会显示类似：`172.17.0.2` 或 `192.168.x.x`

### 1.2 在浏览器中访问WordPress

打开浏览器，访问：
```
http://[IP地址]
```

例如：`http://172.17.0.2`

### 1.3 完成WordPress安装向导

按照页面提示完成：

1. **选择语言** - 选择中文或英文
2. **填写基本信息**：
   - 站点标题：例如 "My WooCommerce Store"
   - 用户名：创建管理员用户名（建议不要用admin）
   - 密码：设置强密码
   - 邮箱：输入您的邮箱
3. **点击"安装WordPress"**

### 1.4 登录管理后台

安装完成后，使用刚才设置的用户名和密码登录：
```
http://[IP地址]/wp-admin
```

---

## 第二步：安装WooCommerce

### 方法1: 使用WP-CLI（推荐）

在Ubuntu终端中运行：

```bash
cd /var/www/wordpress
sudo wp plugin install woocommerce --activate --allow-root
sudo wp theme install storefront --activate --allow-root
```

### 方法2: 通过WordPress后台

1. 登录WordPress后台
2. 进入 **插件 > 安装插件**
3. 搜索 "WooCommerce"
4. 点击 **立即安装** 然后 **启用**
5. 安装 **Storefront** 主题（WooCommerce官方主题）

### 完成WooCommerce设置向导

WooCommerce激活后会自动启动设置向导：

1. **商店设置**：
   - 商店地址
   - 货币：**必须选择 BRL（巴西雷亚尔）** ⚠️
   - 产品类型
   
2. **支付方式**：可以跳过，稍后配置

3. **运费设置**：根据需求配置

4. **推荐插件**：可以跳过

---

## 第三步：部署支付插件

### 方法1: 使用脚本（推荐）

在Ubuntu终端中运行：

```bash
cd ~/wcpay
sudo bash scripts/deploy-plugin.sh
```

### 方法2: 手动部署

```bash
# 复制插件文件
sudo cp -r ~/wcpay /var/www/wordpress/wp-content/plugins/woocommerce-pay

# 排除不需要的文件
cd /var/www/wordpress/wp-content/plugins/woocommerce-pay
sudo rm -rf .git .gitignore node_modules *.md scripts/ docs/

# 设置权限
sudo chown -R www-data:www-data /var/www/wordpress/wp-content/plugins/woocommerce-pay
sudo chmod -R 755 /var/www/wordpress/wp-content/plugins/woocommerce-pay

# 激活插件
cd /var/www/wordpress
sudo wp plugin activate woocommerce-pay --allow-root
```

### 验证插件已激活

在WordPress后台：
- 进入 **插件 > 已安装的插件**
- 确认 **woocommerce-pay** 已激活

或使用命令行：

```bash
cd /var/www/wordpress
sudo wp plugin list --allow-root | grep woocommerce-pay
```

---

## 第四步：配置PIX支付网关

### 4.1 进入支付设置

1. 登录WordPress后台
2. 进入 **WooCommerce > 设置**
3. 点击 **支付** 标签
4. 找到 **PIX Payment**
5. 点击 **管理** 或 **设置**

### 4.2 填写配置信息

**基本设置**：
- ✅ **启用/禁用**：勾选启用
- **标题**：PIX Payment（或自定义）
- **描述**：支付方式描述

**API凭证**（从API文档获取）：
- **API Base URL**：例如 `https://api.example.com`
- **App ID**：您的应用ID
- **Sign Key**：您的签名密钥

**测试设置**：
- ✅ **启用沙盒模式**：测试时启用
- ✅ **启用调试日志**：调试时启用

**保存更改**

---

## 第五步：创建测试产品

### 方法1: 使用WP-CLI

```bash
cd /var/www/wordpress
sudo wp wc product create \
    --name="测试产品" \
    --type=simple \
    --regular_price=100.00 \
    --status=publish \
    --allow-root
```

### 方法2: 通过后台

1. 进入 **产品 > 添加新产品**
2. 填写产品信息：
   - 产品名称
   - 价格：例如 100.00
   - 简短描述
3. **发布**产品

---

## 第六步：测试支付流程

### 6.1 访问商店

在浏览器中访问：
```
http://[IP地址]
```

### 6.2 创建测试订单

1. 点击测试产品
2. 添加到购物车
3. 进入结账页面
4. 填写订单信息：
   - 姓名
   - 邮箱
   - 电话
   - **CPF/CNPJ**（重要！）
   - 地址
5. 选择支付方式：**PIX Payment**
6. 提交订单

### 6.3 查看订单

**后台查看**：
- 进入 **WooCommerce > 订单**
- 查看新创建的订单

**命令行查看**：
```bash
cd /var/www/wordpress
sudo wp wc order list --allow-root --format=table
```

---

## 第七步：查看日志和调试

### 7.1 WordPress调试日志

```bash
sudo tail -f /var/www/wordpress/wp-content/debug.log
```

### 7.2 WooCommerce/PIX支付日志

```bash
# 查看PIX支付日志
sudo tail -f /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log

# 或通过后台查看
# WooCommerce > 状态 > 日志
```

### 7.3 PHP错误日志

```bash
sudo tail -f /var/log/php*-fpm.log
```

### 7.4 Nginx错误日志

```bash
sudo tail -f /var/log/nginx/wordpress_error.log
```

---

## 常用命令参考

### 检查服务状态

```bash
sudo systemctl status nginx mysql php*-fpm
```

### 重启服务

```bash
sudo systemctl restart nginx mysql php*-fpm
```

### 查看订单

```bash
cd /var/www/wordpress
sudo wp wc order list --allow-root
sudo wp wc order get [订单ID] --allow-root
```

### 重新部署插件

```bash
cd ~/wcpay
sudo bash scripts/deploy-plugin.sh
```

### 运行测试

```bash
cd ~/wcpay
sudo bash scripts/test-pix.sh
```

---

## 🎯 快速检查清单

- [ ] WordPress已安装并可访问
- [ ] 管理员账户已创建
- [ ] WooCommerce已安装并激活
- [ ] 货币设置为BRL
- [ ] 支付插件已部署并激活
- [ ] PIX网关已配置
- [ ] API凭证已填写
- [ ] 测试产品已创建
- [ ] 可以创建测试订单
- [ ] 日志正常记录

---

## 需要帮助？

如果遇到问题：

1. 查看日志文件
2. 检查插件是否激活
3. 验证API凭证
4. 查看 `docs/TESTING.md` 测试文档
5. 运行 `sudo bash scripts/test-pix.sh` 检查环境

---

**现在开始**: 获取IP地址 → 访问WordPress → 完成安装 → 配置PIX支付 🚀

