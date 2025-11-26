# 🚀 快速开始指南

## 第一步：进入OrbStack Ubuntu环境

打开终端，运行：

```bash
orbstack shell ubuntu
```

如果没有Ubuntu实例，先在OrbStack UI中创建一个Ubuntu 22.04实例。

## 第二步：准备项目文件

### 方式1: 使用git克隆（推荐）

```bash
cd ~
git clone https://github.com/owenhhs/wcpay.git
cd wcpay
```

### 方式2: 使用共享文件夹

如果OrbStack支持文件共享，尝试：

```bash
cd /mnt/Users/michael/Desktop/woocommerce-pay-20251122
# 或
cd /host/Users/michael/Desktop/woocommerce-pay-20251122
```

### 方式3: 手动复制文件

从Mac复制到Ubuntu（使用scp或其他方式）

## 第三步：运行协助脚本（最简单）

进入项目目录后，运行：

```bash
chmod +x scripts/*.sh
bash scripts/assist-test.sh
```

这个脚本会：
- ✅ 检查当前环境
- ✅ 引导您完成设置
- ✅ 运行测试
- ✅ 查看日志

## 或者：手动执行步骤

### 1. 设置环境

```bash
sudo bash scripts/setup-orbstack.sh
```

这需要几分钟，会安装：
- WordPress
- Nginx
- MySQL
- PHP 8.1

### 2. 安装WooCommerce

```bash
sudo bash scripts/install-woocommerce.sh
```

### 3. 部署插件

```bash
sudo bash scripts/deploy-plugin.sh
```

### 4. 访问WordPress

```bash
# 获取IP地址
hostname -I

# 在浏览器访问
# http://[IP地址]
```

完成WordPress安装向导。

### 5. 运行测试

```bash
# 完整测试
sudo bash scripts/test-pix.sh

# 或使用协助脚本
bash scripts/assist-test.sh
```

## 配置PIX支付

1. 登录WordPress后台: `http://[IP]/wp-admin`
2. 进入 **WooCommerce > 设置 > 支付**
3. 点击 **PIX Payment**
4. 填写配置：
   - ✓ 启用PIX支付
   - API Base URL: （从API文档获取）
   - App ID: （从API文档获取）
   - Sign Key: （从API文档获取）
   - ✓ 启用沙盒模式（测试时）
   - ✓ 启用调试日志
5. 保存更改

## 开始测试

### 创建测试订单

1. 访问商店首页
2. 添加产品到购物车
3. 进入结账页面
4. 选择PIX支付方式
5. 填写订单信息并提交

### 查看日志

```bash
# 实时查看所有日志
sudo tail -f \
  /var/www/wordpress/wp-content/debug.log \
  /var/www/wordpress/wp-content/uploads/woocommerce/logs/pix-*.log \
  /var/log/php8.1-fpm.log
```

## 常用命令

```bash
# 检查环境
sudo bash scripts/check-env.sh

# 运行测试
sudo bash scripts/test-pix.sh

# 测试API
sudo bash scripts/test-api.sh

# 查看订单
cd /var/www/wordpress
sudo wp wc order list --allow-root

# 重启服务
sudo systemctl restart nginx mysql php8.1-fpm
```

## 需要帮助？

1. 查看详细文档：
   - `README_DEBUG.md` - 完整调试指南
   - `START_TESTING.md` - 测试指南
   - `docs/TESTING.md` - 详细测试文档

2. 运行协助脚本：
   ```bash
   bash scripts/assist-test.sh
   ```

3. 检查日志文件：
   ```bash
   sudo tail -f /var/www/wordpress/wp-content/debug.log
   ```

## 下一步

✅ 环境已准备好  
✅ 插件已部署  
✅ 配置已完成  

现在可以开始测试PIX支付功能了！

---

**快速命令**: `bash scripts/assist-test.sh` 🚀

