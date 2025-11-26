# 🚀 立即运行 - 快速指南

## 当前状态

根据环境检查，您现在在 **Mac** 环境中。

## 立即开始

### 步骤1: 打开新终端窗口

打开一个新的终端窗口（保持当前窗口打开查看文档）

### 步骤2: 进入OrbStack Ubuntu环境

在新的终端窗口中运行：

```bash
orbstack shell ubuntu
```

如果没有Ubuntu实例，先创建：
- 打开OrbStack应用
- 点击"+"创建新的Ubuntu 22.04实例
- 或使用命令行：`orbstack create ubuntu`

### 步骤3: 进入项目目录

在Ubuntu环境中：

```bash
# 方式1: 如果通过git克隆
cd ~
git clone https://github.com/owenhhs/wcpay.git
cd wcpay

# 方式2: 如果通过共享文件夹（尝试这些路径）
cd /mnt/Users/michael/Desktop/woocommerce-pay-20251122
# 或
cd /host/Users/michael/Desktop/woocommerce-pay-20251122
```

### 步骤4: 运行协助脚本

```bash
chmod +x scripts/*.sh
bash scripts/assist-test.sh
```

## 协助脚本功能

运行 `bash scripts/assist-test.sh` 后，您会看到菜单：

```
选择操作：
1. 检查环境状态
2. 设置开发环境（首次运行）
3. 运行完整测试
4. 测试API连接
5. 查看日志
6. 手动测试步骤
7. 退出
```

## 首次运行建议

如果是首次运行，建议顺序：

1. **先运行选项2**: 设置开发环境
   - 这会安装WordPress、Nginx、MySQL、PHP

2. **然后运行选项3**: 运行完整测试
   - 这会检查所有组件并创建测试产品

3. **接着运行选项5**: 查看日志
   - 确保一切正常运行

## 快速命令参考

```bash
# 在Ubuntu环境中运行这些命令

# 1. 环境设置（首次）
sudo bash scripts/setup-orbstack.sh
sudo bash scripts/install-woocommerce.sh
sudo bash scripts/deploy-plugin.sh

# 2. 运行测试
sudo bash scripts/test-pix.sh

# 3. 查看日志
sudo tail -f /var/www/wordpress/wp-content/debug.log

# 4. 查看订单
cd /var/www/wordpress
sudo wp wc order list --allow-root
```

## 需要帮助？

如果遇到问题，查看文档：
- `GET_STARTED.md` - 快速开始
- `README_DEBUG.md` - 调试指南
- `docs/TESTING.md` - 测试文档

---

**现在就开始**: 打开新终端 → `orbstack shell ubuntu` → `bash scripts/assist-test.sh` 🚀

