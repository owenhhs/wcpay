# 🔧 Ubuntu环境修复指南

## 当前问题

您在Ubuntu环境中遇到了：
- git命令未找到
- scripts目录不存在
- 项目文件未正确复制

## 🚀 快速修复

### 方法1: 使用修复脚本（推荐）

在Ubuntu终端中，**复制并运行**以下命令：

```bash
# 下载修复脚本（从GitHub）
curl -o /tmp/fix.sh https://raw.githubusercontent.com/owenhhs/wcpay/main/FIX_AND_SETUP.sh 2>/dev/null || \
cat > /tmp/fix.sh << 'SCRIPT_END'
#!/bin/bash
echo "安装工具..."
sudo apt-get update -qq
sudo apt-get install -y git curl wget
cd ~
echo "克隆项目..."
git clone https://github.com/owenhhs/wcpay.git
cd wcpay
chmod +x scripts/*.sh
bash scripts/assist-test.sh
SCRIPT_END

chmod +x /tmp/fix.sh
bash /tmp/fix.sh
```

### 方法2: 手动步骤

#### 步骤1: 安装必要工具

```bash
sudo apt-get update
sudo apt-get install -y git curl wget unzip
```

#### 步骤2: 克隆项目

```bash
cd ~
git clone https://github.com/owenhhs/wcpay.git
cd wcpay
```

#### 步骤3: 运行脚本

```bash
chmod +x scripts/*.sh
bash scripts/assist-test.sh
```

### 方法3: 使用OrbStack文件共享

如果无法使用git，可以通过OrbStack的文件共享功能：

1. **在Mac上**，项目位置：
   ```
   /Users/michael/Desktop/woocommerce-pay-20251122
   ```

2. **在Ubuntu中**，尝试访问：
   ```bash
   cd /mnt/Users/michael/Desktop/woocommerce-pay-20251122
   # 或
   cd /host/Users/michael/Desktop/woocommerce-pay-20251122
   # 或
   cd /Volumes/Users/michael/Desktop/woocommerce-pay-20251122
   ```

3. 如果找到了，直接运行：
   ```bash
   chmod +x scripts/*.sh
   bash scripts/assist-test.sh
   ```

## ✅ 一键修复命令（复制运行）

在Ubuntu终端中直接运行：

```bash
sudo apt-get update && \
sudo apt-get install -y git curl wget && \
cd ~ && \
git clone https://github.com/owenhhs/wcpay.git && \
cd wcpay && \
chmod +x scripts/*.sh && \
bash scripts/assist-test.sh
```

## 🔍 检查当前状态

运行以下命令查看当前状态：

```bash
# 检查当前位置
pwd

# 查看当前目录内容
ls -la

# 检查git是否安装
which git || echo "git未安装"

# 检查网络连接
ping -c 2 github.com || echo "无法连接GitHub"
```

## 📝 如果网络有问题

如果无法访问GitHub，可以：

1. **使用本地文件复制**：
   - 在OrbStack UI中配置文件共享
   - 或者使用scp从Mac复制文件

2. **手动创建目录结构**：
   ```bash
   mkdir -p ~/wcpay/scripts
   # 然后手动复制文件
   ```

## 🆘 需要帮助？

如果仍然有问题，告诉我：
1. 您当前在哪个目录？（运行 `pwd`）
2. 能否访问GitHub？（运行 `ping github.com`）
3. 是否能看到Mac的文件共享？（运行 `ls /mnt` 或 `ls /host`）

---

**立即修复**: 复制上面的"一键修复命令"运行！🚀

