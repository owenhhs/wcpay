# 🚀 下一步操作指南 - Docker环境

## 📋 当前进度检查

在继续之前，请确认你已经完成了：

- [ ] Docker已安装
- [ ] Docker权限已配置
- [ ] 代码已更新到最新版本

## 🔍 快速检查

运行以下命令检查状态：

```bash
# 检查Docker
docker --version
docker ps

# 检查代码
cd ~/wcpay
git status
```

## 📝 完整步骤

### 步骤1: 确认Docker已安装 ✅

```bash
docker --version
docker ps
```

**如果Docker未安装**：
```bash
cd ~/wcpay
bash docker/install-docker-orbstack.sh
newgrp docker  # 或退出重新登录
```

### 步骤2: 启动Docker WordPress环境 🐳

```bash
cd ~/wcpay
bash docker/orbstack-start.sh
```

这会启动：
- WordPress容器 (端口8080)
- MySQL数据库容器 (端口3306)
- phpMyAdmin容器 (端口8081)

**等待30-60秒让容器完全启动**

### 步骤3: 配置WordPress ⚙️

```bash
bash docker/docker-setup.sh
```

这会自动：
- 安装WordPress
- 安装WooCommerce
- 激活支付插件

### 步骤4: 访问WordPress 🌐

**在Ubuntu中访问**：
- 前台: http://localhost:8080
- 后台: http://localhost:8080/wp-admin

**从Mac访问**：
1. 获取Ubuntu IP: `hostname -I`
2. 访问: http://[IP]:8080

**登录信息**：
- 用户名: `admin`
- 密码: `admin123`
- ⚠️ **重要**: 登录后立即更改密码！

### 步骤5: 配置支付插件 💳

1. **登录WordPress后台**
   - 访问: http://localhost:8080/wp-admin
   - 使用 admin/admin123 登录

2. **安装WooCommerce**（如果还没安装）
   - 插件 → 已安装的插件
   - 找到WooCommerce → 激活

3. **配置WooCommerce**
   - WooCommerce → 设置
   - 完成设置向导（如果出现）

4. **配置支付插件**
   - WooCommerce → 设置 → 支付
   - 找到 "pay" 或 "LarkPay" 支付方式
   - 点击 "管理" 或 "设置"
   - 填写API凭证（从文档获取）
   - 启用支付网关

### 步骤6: 测试支付功能 🧪

1. **创建测试产品**
   - 产品 → 添加新产品
   - 设置价格、库存等

2. **测试结账流程**
   - 访问商店前台
   - 添加产品到购物车
   - 进入结账页面
   - 选择支付方式
   - 完成支付测试

## 🔧 常用命令参考

### Docker管理

```bash
# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f wordpress
docker-compose logs -f db

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 进入WordPress容器
docker exec -it wp-dev-wordpress bash
```

### WP-CLI命令

```bash
# 安装插件
docker exec -it wp-dev-wordpress wp plugin install woocommerce --activate --allow-root

# 查看插件列表
docker exec -it wp-dev-wordpress wp plugin list --allow-root

# 激活支付插件
docker exec -it wp-dev-wordpress wp plugin activate woocommerce-pay --allow-root

# 查看站点信息
docker exec -it wp-dev-wordpress wp option get siteurl --allow-root
```

## 📚 相关文档

- 📖 [Docker详细指南](docs/ORBSTACK_DOCKER.md)
- 📖 [插件安装指南](docs/INSTALLATION.md)
- 📖 [Pix集成文档](docs/PIX_INTEGRATION.md)
- 📖 [测试指南](docs/TESTING.md)

## 🐛 遇到问题？

### Docker容器启动失败

```bash
# 查看详细日志
docker-compose logs

# 检查端口占用
sudo lsof -i :8080

# 重新启动
docker-compose down
docker-compose up -d
```

### 无法访问WordPress

```bash
# 检查容器状态
docker-compose ps

# 检查日志
docker-compose logs wordpress

# 测试连接
curl http://localhost:8080
```

### 数据库连接失败

```bash
# 检查数据库容器
docker-compose logs db

# 重启数据库
docker-compose restart db

# 进入数据库容器测试
docker exec -it wp-dev-db mysql -u wpuser -pwppass123 wordpress
```

## ✅ 检查清单

完成所有步骤后，确认：

- [ ] WordPress可以访问
- [ ] 可以登录后台
- [ ] WooCommerce已安装并激活
- [ ] 支付插件已激活
- [ ] 可以创建产品
- [ ] 可以进入结账页面
- [ ] 支付方式显示正常

## 🎯 下一步目标

1. ✅ 环境搭建完成
2. ⏭️ 配置API凭证
3. ⏭️ 测试支付流程
4. ⏭️ 调试和优化
5. ⏭️ 部署到生产环境

---

**准备好了吗？让我们开始！** 🚀

