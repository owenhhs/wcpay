# 🐳 在OrbStack中使用Docker

## 📋 概述

本指南说明如何在OrbStack的Ubuntu实例中使用Docker运行WordPress插件开发环境。

## 为什么在OrbStack中使用Docker？

- ✅ **隔离性更好** - Docker容器在Ubuntu中运行，与Ubuntu系统隔离
- ✅ **环境统一** - 与生产环境更接近
- ✅ **易于管理** - 可以同时运行多个不同版本的项目
- ✅ **资源控制** - OrbStack可以限制资源使用

## 🚀 快速开始

### 前提条件

1. **OrbStack已安装并运行**
2. **Ubuntu实例已创建**

### 安装步骤

#### 1. 进入OrbStack Ubuntu

```bash
# 在Mac终端运行
orbstack shell ubuntu
```

或者直接在OrbStack中打开Ubuntu实例。

#### 2. 克隆项目（如果还没有）

```bash
cd ~
git clone https://github.com/owenhhs/wcpay.git
cd wcpay
```

#### 3. 安装Docker

```bash
cd ~/wcpay
chmod +x docker/*.sh
bash docker/install-docker-orbstack.sh
```

**注意**: 安装完成后，如果用户被添加到docker组，需要运行：
```bash
newgrp docker
```

或者退出重新登录Ubuntu。

#### 4. 启动Docker环境

```bash
cd ~/wcpay
bash docker/orbstack-start.sh
```

#### 5. 配置WordPress

```bash
bash docker/docker-setup.sh
```

### 访问WordPress

#### 方式1: 从Ubuntu内部访问

```bash
# 在Ubuntu中打开浏览器（如果安装了）
firefox http://localhost:8080
```

或者使用curl测试：
```bash
curl http://localhost:8080
```

#### 方式2: 从Mac访问

1. 获取Ubuntu IP地址：
   ```bash
   hostname -I
   ```

2. 在Mac浏览器访问：
   - WordPress: `http://[Ubuntu IP]:8080`
   - phpMyAdmin: `http://[Ubuntu IP]:8081`

**注意**: 如果无法从Mac访问，可能需要配置OrbStack网络或防火墙。

## 🔧 配置网络访问

### 检查端口是否可访问

在Mac终端运行：
```bash
# 获取Ubuntu IP
orbstack ip ubuntu

# 测试连接
curl http://[Ubuntu IP]:8080
```

### 配置防火墙（如果需要）

```bash
# 在Ubuntu中运行
sudo ufw allow 8080/tcp
sudo ufw allow 8081/tcp
sudo ufw status
```

## 📦 服务说明

| 服务 | 容器名 | 端口 | 说明 |
|------|--------|------|------|
| WordPress | wp-dev-wordpress | 8080 | WordPress网站 |
| MySQL | wp-dev-db | 3306 | 数据库（可选暴露） |
| phpMyAdmin | wp-dev-phpmyadmin | 8081 | 数据库管理界面 |

## 🔧 常用命令

### Docker管理

```bash
# 查看容器状态
docker-compose ps
# 或
docker compose ps

# 查看日志
docker-compose logs -f wordpress
docker-compose logs -f db

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看资源使用
docker stats
```

### 进入容器

```bash
# 进入WordPress容器
docker exec -it wp-dev-wordpress bash

# 在容器中使用WP-CLI
docker exec -it wp-dev-wordpress wp --info --allow-root

# 进入数据库容器
docker exec -it wp-dev-db bash
```

### WP-CLI命令

```bash
# 安装WordPress
docker exec -it wp-dev-wordpress wp core install \
    --url=http://localhost:8080 \
    --title="My Store" \
    --admin_user=admin \
    --admin_password=admin123 \
    --admin_email=admin@example.com \
    --allow-root

# 安装WooCommerce
docker exec -it wp-dev-wordpress wp plugin install woocommerce --activate --allow-root

# 激活支付插件
docker exec -it wp-dev-wordpress wp plugin activate woocommerce-pay --allow-root

# 查看插件列表
docker exec -it wp-dev-wordpress wp plugin list --allow-root
```

## 🐛 故障排除

### 问题1: Docker命令需要sudo

**解决方案**:
```bash
# 将用户添加到docker组
sudo usermod -aG docker $USER

# 应用更改
newgrp docker

# 或退出重新登录
exit
# 然后重新进入Ubuntu
```

### 问题2: 端口被占用

**错误**: `Bind for 0.0.0.0:8080 failed: port is already allocated`

**解决方案**:
```bash
# 查看占用端口的进程
sudo lsof -i :8080

# 修改docker-compose.yml中的端口
# 或停止占用端口的服务
```

### 问题3: 无法从Mac访问

**解决方案**:
1. 检查Ubuntu IP: `hostname -I`
2. 检查防火墙: `sudo ufw status`
3. 测试连接: `curl http://localhost:8080` (在Ubuntu中)
4. 配置OrbStack网络端口转发（如果支持）

### 问题4: Docker服务未启动

**解决方案**:
```bash
# 启动Docker服务
sudo systemctl start docker

# 或
sudo service docker start

# 检查状态
sudo systemctl status docker
```

### 问题5: 容器启动失败

**解决方案**:
```bash
# 查看详细日志
docker-compose logs

# 检查磁盘空间
df -h

# 清理未使用的Docker资源
docker system prune -a

# 重新启动
docker-compose down
docker-compose up -d
```

## 🔄 数据管理

### 备份数据库

```bash
# 导出数据库
docker exec wp-dev-db mysqldump -u wpuser -pwppass123 wordpress > backup.sql

# 或使用WP-CLI
docker exec -it wp-dev-wordpress wp db export backup.sql --allow-root
```

### 恢复数据库

```bash
# 导入数据库
docker exec -i wp-dev-db mysql -u wpuser -pwppass123 wordpress < backup.sql

# 或使用WP-CLI
docker exec -i wp-dev-wordpress wp db import backup.sql --allow-root
```

## 📊 资源监控

```bash
# 查看Docker资源使用
docker stats

# 查看磁盘使用
docker system df

# 查看容器资源限制
docker inspect wp-dev-wordpress | grep -i memory
docker inspect wp-dev-wordpress | grep -i cpu
```

## 🆚 方案对比

| 特性 | OrbStack + Docker | Mac直接Docker |
|------|-------------------|---------------|
| 隔离性 | ✅ 双重隔离 | ✅ 容器隔离 |
| 性能 | ⚠️ 略慢 | ✅ 更快 |
| 资源占用 | ⚠️ 更高 | ✅ 更低 |
| 学习价值 | ✅ 更高 | ⚠️ 一般 |
| 生产环境相似度 | ✅ 更相似 | ⚠️ 一般 |

## 📚 相关文档

- 📖 [Docker设置指南](DOCKER_SETUP.md)
- 📖 [开发环境设置](DEV_SETUP.md)
- 📖 [OrbStack设置指南](ORBSTACK_SETUP.md)

## 💡 最佳实践

1. **开发环境**: 使用OrbStack + Docker（更接近生产）
2. **快速测试**: 直接在Mac上使用Docker（更快）
3. **生产部署**: 根据实际情况选择服务器配置

---

**推荐**: 在OrbStack中使用Docker进行开发！🐳

