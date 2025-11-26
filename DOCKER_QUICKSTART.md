# 🐳 Docker开发环境 - 快速开始

## 推荐使用Docker！

对于WordPress插件开发，**强烈推荐使用Docker**，因为：

✅ **环境隔离** - 不污染你的Mac/Windows系统  
✅ **一键启动** - 几分钟就能启动完整环境  
✅ **团队统一** - 所有人环境完全一致  
✅ **易于清理** - 删除容器即可完全清除  
✅ **接近生产** - 更接近真实服务器环境  

## 🚀 快速启动（3步）

### 1. 确保Docker运行

```bash
# 检查Docker是否运行
docker ps
```

如果没安装Docker：
- **macOS**: 安装 [Docker Desktop](https://www.docker.com/products/docker-desktop) 或 [OrbStack](https://orbstack.dev/)
- **Windows**: 安装 [Docker Desktop](https://www.docker.com/products/docker-desktop)
- **Linux**: `sudo apt install docker.io docker-compose`

### 2. 启动Docker环境

```bash
# 在项目根目录运行
bash docker/docker-start.sh
```

或手动启动：

```bash
docker-compose up -d
```

### 3. 访问WordPress

- **前台**: http://localhost:8080
- **后台**: http://localhost:8080/wp-admin
- **数据库管理**: http://localhost:8081 (phpMyAdmin)

## 📋 下一步

### 完成WordPress安装

方式1: 通过浏览器（推荐）
1. 访问 http://localhost:8080
2. 按照向导完成安装

方式2: 使用命令行（更快）
```bash
bash docker/docker-setup.sh
```

登录信息：
- 用户名: `admin`
- 密码: `admin123`
- ⚠️ **重要**: 登录后立即更改密码！

## 🔧 常用命令

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 查看日志
docker-compose logs -f

# 进入WordPress容器
docker exec -it wp-dev-wordpress bash

# 重启服务
docker-compose restart

# 查看状态
docker-compose ps
```

## 📦 服务说明

| 服务 | 端口 | 说明 |
|------|------|------|
| WordPress | 8080 | WordPress网站 |
| MySQL | 3306 | 数据库（可选暴露） |
| phpMyAdmin | 8081 | 数据库管理界面 |

## 🆚 Docker vs 直接安装

| 特性 | Docker ✅ | 直接安装 |
|------|-----------|---------|
| 环境隔离 | ✅ 完全隔离 | ❌ 污染系统 |
| 安装时间 | ⚡ 5分钟 | 🐌 30-60分钟 |
| 清理 | ✅ 一键删除 | ❌ 手动清理 |
| 多版本测试 | ✅ 轻松 | ❌ 困难 |
| 团队协作 | ✅ 完全一致 | ⚠️ 可能有差异 |

## 🐛 遇到问题？

查看详细文档: [DOCKER_SETUP.md](docs/DOCKER_SETUP.md)

常见问题：
1. **端口被占用**: 修改 `docker-compose.yml` 中的端口号
2. **容器启动失败**: 运行 `docker-compose logs` 查看错误
3. **网络超时**: 配置Docker镜像加速器

## 📚 完整文档

- 📖 [详细Docker设置指南](docs/DOCKER_SETUP.md)
- 📖 [插件安装配置](docs/INSTALLATION.md)
- 📖 [开发环境设置](docs/DEV_SETUP.md)

---

**推荐**: 使用Docker进行开发！🐳

