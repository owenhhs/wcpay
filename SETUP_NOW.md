# 🚀 立即设置开发环境

## 当前状态

环境检查显示所有组件都未安装。现在开始设置完整环境。

## ✅ 一键设置（推荐）

在Ubuntu终端中，**确保您在项目目录**，然后运行：

```bash
# 如果在 ~/wcpay 目录
cd ~/wcpay

# 运行自动设置脚本
chmod +x scripts/auto-setup.sh
bash scripts/auto-setup.sh
```

## 或者：分步执行

### 步骤1: 设置基础环境

```bash
cd ~/wcpay
sudo bash scripts/setup-orbstack.sh
```

这将安装：
- PHP 8.1
- MySQL
- Nginx
- WordPress
- WP-CLI

**预计时间：5-10分钟**

### 步骤2: 安装WooCommerce

```bash
sudo bash scripts/install-woocommerce.sh
```

### 步骤3: 部署插件

```bash
sudo bash scripts/deploy-plugin.sh
```

## 📍 快速命令（复制运行）

在Ubuntu终端中运行：

```bash
cd ~/wcpay && \
chmod +x scripts/*.sh && \
sudo bash scripts/setup-orbstack.sh && \
sudo bash scripts/install-woocommerce.sh && \
sudo bash scripts/deploy-plugin.sh
```

## 🎯 设置完成后的步骤

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
- 填写API凭证并启用

### 6. 运行测试

```bash
sudo bash scripts/test-pix.sh
```

## ⚠️ 注意事项

1. **设置过程需要几分钟**，请耐心等待
2. **需要sudo权限**，可能需要输入密码
3. **确保网络连接正常**（需要下载软件包）
4. 安装过程中可能会提示一些确认，选择 **Y** 继续

## 🔍 查看安装进度

如果想知道安装进度，可以：

```bash
# 查看MySQL安装状态
sudo systemctl status mysql

# 查看Nginx安装状态
sudo systemctl status nginx

# 查看PHP安装状态
php -v
```

## 🆘 如果遇到问题

1. **网络问题**：确保Ubuntu可以访问互联网
2. **权限问题**：确保使用sudo运行脚本
3. **端口占用**：如果80端口被占用，需要先停止其他服务

---

**现在就开始**: 运行 `bash scripts/auto-setup.sh` 🚀

