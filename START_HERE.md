# 🎯 开始测试 - 简单指引

## 当前状态

您目前在 **Mac** 环境中。需要进入 **OrbStack Ubuntu** 环境来运行测试。

## 🚀 最简单的开始方法

### 方法1: 使用OrbStack应用（推荐）

1. **打开OrbStack应用**
   - 在Mac上打开OrbStack应用
   - 如果没有安装，访问: https://orbstack.dev/

2. **启动Ubuntu实例**
   - 在OrbStack UI中点击"+"创建Ubuntu 22.04实例
   - 或使用已有的Ubuntu实例

3. **在Ubuntu终端中运行**
   ```bash
   # 进入项目目录（通过共享文件夹或git克隆）
   cd /mnt/Users/michael/Desktop/woocommerce-pay-20251122
   # 或
   cd ~ && git clone https://github.com/owenhhs/wcpay.git && cd wcpay
   
   # 运行协助脚本
   chmod +x scripts/*.sh
   bash scripts/assist-test.sh
   ```

### 方法2: 如果OrbStack已配置好命令行

直接在Mac终端运行：

```bash
cd /Users/michael/Desktop/woocommerce-pay-20251122

# 尝试进入Ubuntu（如果命令可用）
orbstack shell ubuntu
# 或
docker exec -it ubuntu bash
```

然后在Ubuntu中：

```bash
cd /mnt/Users/michael/Desktop/woocommerce-pay-20251122
bash scripts/assist-test.sh
```

## 📋 协助脚本功能

运行 `bash scripts/assist-test.sh` 后，选择：

- **选项2**: 设置开发环境（首次运行必须）
- **选项3**: 运行完整测试
- **选项5**: 查看日志

## ⚡ 快速命令（在Ubuntu环境中）

```bash
# 1. 设置环境（首次）
sudo bash scripts/setup-orbstack.sh

# 2. 安装WooCommerce
sudo bash scripts/install-woocommerce.sh

# 3. 部署插件
sudo bash scripts/deploy-plugin.sh

# 4. 运行测试
sudo bash scripts/test-pix.sh
```

## 🔍 检查是否在Ubuntu环境中

运行：

```bash
cat /etc/os-release
```

如果看到Ubuntu相关信息，说明已经在Ubuntu环境中。

## ❓ 需要帮助？

如果遇到问题：

1. 确保OrbStack已安装并运行
2. 确保Ubuntu实例已创建
3. 查看详细文档：`GET_STARTED.md`

---

**现在就开始**: 打开OrbStack应用 → 启动Ubuntu → 运行 `bash scripts/assist-test.sh` 🚀

