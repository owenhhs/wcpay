# 🐳 在OrbStack中安装Docker - 完整指南

## 📋 重要说明

**Docker安装脚本适用于任何Ubuntu系统**，包括：
- ✅ OrbStack Ubuntu实例
- ✅ VMware虚拟机
- ✅ VirtualBox虚拟机
- ✅ 物理Ubuntu服务器
- ✅ WSL2 (Windows)

即使脚本没有明确检测到"OrbStack"标志，也可以正常安装Docker。

## 🚀 快速开始

### 步骤1: 进入OrbStack Ubuntu

#### 方式A: 通过OrbStack GUI
1. 打开OrbStack应用
2. 启动Ubuntu实例
3. 点击"Terminal"或"Shell"

#### 方式B: 通过命令行
```bash
# 在Mac终端运行
orbstack shell ubuntu
```

### 步骤2: 检查环境（可选）

```bash
cd ~/wcpay
bash docker/check-orbstack.sh
```

这会显示当前环境信息，但不影响Docker安装。

### 步骤3: 更新代码

```bash
cd ~/wcpay
git fetch origin main
git reset --hard origin/main
chmod +x docker/*.sh scripts/*.sh
```

### 步骤4: 安装Docker

```bash
bash docker/install-docker-orbstack.sh
```

**即使看到"无法明确检测OrbStack环境"的提示也没关系，可以继续！**

### 步骤5: 配置Docker权限

如果安装脚本提示需要重新登录或添加到docker组：

```bash
# 方法1: 切换到docker组
newgrp docker

# 方法2: 退出并重新登录Ubuntu
exit
# 然后重新进入: orbstack shell ubuntu
```

### 步骤6: 测试Docker

```bash
docker ps
```

如果不需要sudo就能运行，说明配置成功！

### 步骤7: 启动WordPress环境

```bash
cd ~/wcpay
bash docker/orbstack-start.sh
```

## ⚠️ 常见问题

### 问题1: "这看起来不是在OrbStack环境中"

**回答**: 这是正常的！脚本可能无法100%检测到OrbStack，但Docker安装不受影响。

**解决方案**: 直接继续安装，Docker可以在任何Ubuntu系统上安装。

### 问题2: Docker命令需要sudo

**原因**: 用户没有在docker组中

**解决方案**:
```bash
# 添加用户到docker组
sudo usermod -aG docker $USER

# 应用更改
newgrp docker

# 或退出重新登录
exit
```

### 问题3: 如何确认在OrbStack中？

**检查方法**:
```bash
# 检查OrbStack特定文件
ls -la /run/orbstack 2>/dev/null
ls -la /opt/orbstack 2>/dev/null

# 检查主机名
hostname

# 检查系统信息
cat /etc/os-release
```

但即使没有这些标志，如果在OrbStack应用中打开Ubuntu，那就是在OrbStack中。

### 问题4: Docker服务启动失败

**解决方案**:
```bash
# 启动Docker服务
sudo systemctl start docker

# 或使用service命令
sudo service docker start

# 检查状态
sudo systemctl status docker
```

### 问题5: 如何确认安装成功？

**验证步骤**:
```bash
# 1. 检查Docker版本
docker --version

# 2. 检查Docker服务
docker ps

# 3. 检查docker-compose
docker compose version
# 或
docker-compose --version

# 4. 运行测试容器
docker run hello-world
```

## 📝 完整安装流程

```bash
# 1. 进入Ubuntu（如果还没进入）
orbstack shell ubuntu

# 2. 进入项目目录
cd ~/wcpay

# 3. 更新代码
git fetch origin main && git reset --hard origin/main
chmod +x docker/*.sh scripts/*.sh

# 4. 检查环境（可选）
bash docker/check-orbstack.sh

# 5. 安装Docker
bash docker/install-docker-orbstack.sh

# 6. 配置权限
newgrp docker  # 或退出重新登录

# 7. 测试Docker
docker ps

# 8. 启动WordPress
bash docker/orbstack-start.sh

# 9. 配置WordPress
bash docker/docker-setup.sh
```

## 🎯 关键点

1. **环境检测是可选的** - 即使检测失败，Docker也能正常安装
2. **适用于所有Ubuntu系统** - 不只是OrbStack
3. **权限配置很重要** - 确保用户在docker组中
4. **重新登录可能需要** - 如果权限不生效

## 📚 相关文档

- [OrbStack Docker详细指南](docs/ORBSTACK_DOCKER.md)
- [Docker设置指南](docs/DOCKER_SETUP.md)

---

**记住**: 即使没有明确检测到OrbStack，也可以继续安装Docker！🐳

