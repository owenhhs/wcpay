# Docker开发环境设置指南

## 📋 概述

使用Docker运行WordPress插件开发环境是最推荐的方式，因为：

- ✅ **环境隔离** - 不污染主机系统
- ✅ **一键启动** - 快速启动/停止所有服务
- ✅ **版本控制** - 固定版本，团队统一
- ✅ **易于分享** - 任何人clone后即可运行
- ✅ **接近生产** - 与生产环境更相似

## 🚀 快速开始

### 前提条件

1. **安装Docker Desktop**（macOS/Windows）
   - macOS: 下载 [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
   - Windows: 下载 [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
   - Linux: 安装 Docker Engine 和 Docker Compose

2. **安装OrbStack**（可选，macOS推荐）
   - OrbStack提供更快的Docker体验
   - 下载：[OrbStack官网](https://orbstack.dev/)

### 一键启动

```bash
# 1. 启动Docker容器
bash docker/docker-start.sh

# 2. 配置WordPress和WooCommerce（可选，也可以手动配置）
bash docker/docker-setup.sh
```

### 手动启动

```bash
# 启动所有服务
docker-compose up -d

# 或者使用新版本命令
docker compose up -d

# 查看日志
docker-compose logs -f

# 查看容器状态
docker-compose ps
```

## 📦 服务说明

### 1. WordPress容器
- **端口**: `8080:80`
- **访问**: http://localhost:8080
- **数据卷**: 
  - WordPress文件: `wordpress_data` volume
  - 插件代码: `./` (当前目录挂载为只读)

### 2. MySQL数据库容器
- **端口**: `3306:3306`
- **数据库名**: `wordpress`
- **用户名**: `wpuser`
- **密码**: `wppass123`
- **Root密码**: `rootpass123`

### 3. phpMyAdmin容器
- **端口**: `8081:80`
- **访问**: http://localhost:8081
- **用途**: 数据库管理界面

## 🔧 常用命令

### 容器管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 停止并删除数据卷（⚠️会删除所有数据）
docker-compose down -v

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f wordpress
docker-compose logs -f db
```

### 进入容器

```bash
# 进入WordPress容器
docker exec -it wp-dev-wordpress bash

# 进入数据库容器
docker exec -it wp-dev-db bash

# 在容器中使用WP-CLI
docker exec -it wp-dev-wordpress wp --info --allow-root
```

### WP-CLI命令示例

```bash
# 安装WordPress
docker exec -it wp-dev-wordpress wp core install \
    --url=http://localhost:8080 \
    --title="My Store" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root

# 安装插件
docker exec -it wp-dev-wordpress wp plugin install woocommerce --activate --allow-root

# 查看插件列表
docker exec -it wp-dev-wordpress wp plugin list --allow-root

# 激活支付插件
docker exec -it wp-dev-wordpress wp plugin activate woocommerce-pay --allow-root
```

## 📁 项目结构

```
woocommerce-pay/
├── docker-compose.yml          # Docker Compose配置
├── Dockerfile                  # WordPress镜像定制
├── docker/
│   ├── php.ini                # PHP配置
│   ├── docker-start.sh        # 启动脚本
│   └── docker-setup.sh        # 设置脚本
└── ...                        # 插件代码
```

## ⚙️ 配置说明

### 修改端口

编辑 `docker-compose.yml`:

```yaml
wordpress:
  ports:
    - "9000:80"  # 改为9000端口

phpmyadmin:
  ports:
    - "9001:80"  # 改为9001端口
```

### 修改数据库密码

编辑 `docker-compose.yml` 中的环境变量:

```yaml
environment:
  WORDPRESS_DB_PASSWORD: your_new_password
  MYSQL_PASSWORD: your_new_password
```

### 挂载插件代码

当前配置已将整个项目目录挂载为只读：

```yaml
volumes:
  - ./:/var/www/html/wp-content/plugins/woocommerce-pay:ro
```

如需可写权限，移除`:ro`：

```yaml
volumes:
  - ./:/var/www/html/wp-content/plugins/woocommerce-pay
```

## 🐛 故障排除

### 问题1: 端口被占用

**错误**: `Bind for 0.0.0.0:8080 failed: port is already allocated`

**解决**:
```bash
# 查看占用端口的进程
lsof -i :8080

# 修改docker-compose.yml中的端口
# 或停止占用端口的服务
```

### 问题2: 容器无法启动

**解决**:
```bash
# 查看日志
docker-compose logs

# 重新构建
docker-compose down
docker-compose up -d --build
```

### 问题3: 数据库连接失败

**解决**:
```bash
# 检查数据库容器是否运行
docker-compose ps

# 重启数据库容器
docker-compose restart db

# 查看数据库日志
docker-compose logs db
```

### 问题4: 插件修改不生效

**原因**: 插件目录可能挂载为只读

**解决**:
1. 编辑 `docker-compose.yml`，移除`:ro`标志
2. 重启容器: `docker-compose restart wordpress`

### 问题5: Docker网络超时

**解决**:
```bash
# 使用国内镜像源（如果在中国）
# 编辑 ~/.docker/daemon.json
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}

# 重启Docker服务
```

## 🔄 数据备份与恢复

### 备份数据库

```bash
# 导出数据库
docker exec wp-dev-db mysqldump -u wpuser -pwppass123 wordpress > backup.sql

# 或者使用WP-CLI
docker exec -it wp-dev-wordpress wp db export backup.sql --allow-root
```

### 恢复数据库

```bash
# 导入数据库
docker exec -i wp-dev-db mysql -u wpuser -pwppass123 wordpress < backup.sql

# 或者使用WP-CLI
docker exec -i wp-dev-wordpress wp db import backup.sql --allow-root
```

## 🆚 Docker vs 直接安装对比

| 特性 | Docker | 直接安装 |
|------|--------|---------|
| 环境隔离 | ✅ 完全隔离 | ❌ 污染主机 |
| 安装速度 | ⚡ 快速 | 🐌 较慢 |
| 清理 | ✅ 一键删除 | ❌ 手动清理 |
| 多版本 | ✅ 可运行多个 | ❌ 冲突 |
| 跨平台 | ✅ 完全一致 | ⚠️ 可能有差异 |
| 学习曲线 | ⚠️ 需要了解Docker | ✅ 更直观 |

## 📚 下一步

1. ✅ 完成Docker环境启动
2. 📖 阅读 [插件安装指南](../docs/INSTALLATION.md)
3. 🔧 配置支付网关
4. 🧪 开始测试支付功能

---

**推荐**: 使用Docker进行开发，部署到生产环境时根据实际情况选择。 🐳

