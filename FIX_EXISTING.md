# 🔧 解决目录已存在的问题

## 问题

```
fatal: destination path 'wcpay' already exists and is not an empty directory.
```

## ✅ 解决方案

### 方法1: 删除现有目录重新克隆（最简单）

在Ubuntu终端中运行：

```bash
cd ~
rm -rf wcpay
git clone https://github.com/owenhhs/wcpay.git
cd wcpay
chmod +x scripts/*.sh
bash scripts/assist-test.sh
```

### 方法2: 更新现有目录

如果现有目录已经是git仓库，可以更新：

```bash
cd ~/wcpay
git pull origin main
chmod +x scripts/*.sh
bash scripts/assist-test.sh
```

### 方法3: 使用修复脚本

下载并运行修复脚本：

```bash
cd ~
curl -o fix-dir.sh https://raw.githubusercontent.com/owenhhs/wcpay/main/scripts/fix-existing-dir.sh
chmod +x fix-dir.sh
bash fix-dir.sh
```

或者直接在Ubuntu终端运行：

```bash
cd ~
rm -rf wcpay && \
git clone https://github.com/owenhhs/wcpay.git && \
cd wcpay && \
chmod +x scripts/*.sh && \
bash scripts/assist-test.sh
```

## 🚀 一键解决命令

在Ubuntu终端中，复制并运行：

```bash
cd ~ && rm -rf wcpay && git clone https://github.com/owenhhs/wcpay.git && cd wcpay && chmod +x scripts/*.sh && bash scripts/assist-test.sh
```

## 📋 检查现有目录

如果想先查看现有目录内容：

```bash
cd ~/wcpay
ls -la
ls -la scripts/ 2>/dev/null || echo "scripts目录不存在"
```

如果scripts目录存在但内容不完整，建议删除重新克隆。

---

**推荐**: 使用方法1删除重新克隆，最简单直接！🚀

