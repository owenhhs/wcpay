# 📋 复制并运行 - 快速开始

## 🚀 最简单的方法

### 步骤1: 打开OrbStack应用并启动Ubuntu

1. 打开Mac上的 **OrbStack** 应用
2. 如果没有Ubuntu实例，点击 **"+"** 创建 Ubuntu 22.04
3. 启动Ubuntu实例

### 步骤2: 在Ubuntu终端中复制运行以下命令

打开Ubuntu实例的终端，然后**复制粘贴**以下命令：

```bash
# 进入项目目录（尝试这些路径，选择存在的）
cd /mnt/Users/michael/Desktop/woocommerce-pay-20251122 2>/dev/null || \
cd /host/Users/michael/Desktop/woocommerce-pay-20251122 2>/dev/null || \
(cd ~ && git clone https://github.com/owenhhs/wcpay.git && cd wcpay)

# 给脚本添加执行权限
chmod +x scripts/*.sh

# 运行协助脚本
bash scripts/assist-test.sh
```

### 步骤3: 根据菜单选择

协助脚本会显示菜单，**首次运行**选择：

1. **输入 2** - 设置开发环境（安装WordPress等）
2. 等待安装完成（几分钟）
3. **输入 3** - 运行完整测试
4. **输入 5** - 查看日志

---

## 或者：分步手动执行

如果不想使用协助脚本，可以手动执行：

```bash
# 1. 设置环境
sudo bash scripts/setup-orbstack.sh

# 2. 安装WooCommerce
sudo bash scripts/install-woocommerce.sh

# 3. 部署插件
sudo bash scripts/deploy-plugin.sh

# 4. 运行测试
sudo bash scripts/test-pix.sh
```

---

## 📍 当前项目位置

项目在Mac上的位置：
```
/Users/michael/Desktop/woocommerce-pay-20251122
```

在Ubuntu中可能的位置：
- `/mnt/Users/michael/Desktop/woocommerce-pay-20251122`
- `/host/Users/michael/Desktop/woocommerce-pay-20251122`
- 或使用git克隆到 `~/wcpay`

---

## ✅ 快速检查清单

运行协助脚本后，确保：
- [ ] WordPress已安装
- [ ] WooCommerce已安装并激活
- [ ] 支付插件已部署并激活
- [ ] 货币设置为BRL
- [ ] PIX网关可以配置

---

**现在就开始：打开OrbStack → 启动Ubuntu → 复制上面的命令运行！** 🚀

