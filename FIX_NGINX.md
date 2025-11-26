# 🔧 修复Nginx配置问题

## 问题

Nginx配置目录不存在，导致配置失败：
```
tee: /etc/nginx/sites-available/wordpress: No such file or directory
```

## ✅ 快速修复

在Ubuntu终端中运行：

```bash
cd ~/wcpay
git pull origin main
sudo bash scripts/fix-nginx.sh
```

这会：
- 创建必要的Nginx配置目录
- 检测PHP-FPM socket
- 创建WordPress站点配置
- 测试配置并重启Nginx

## 然后继续WordPress安装

修复Nginx后，继续安装WordPress：

```bash
# 方式1: 使用WP-CLI
sudo bash scripts/install-wordpress-cli.sh

# 方式2: 通过浏览器
# 访问: http://[IP地址]
```

## 验证

修复后验证：

```bash
# 检查Nginx配置
sudo nginx -t

# 检查Nginx状态
sudo systemctl status nginx

# 查看错误日志
sudo tail -20 /var/log/nginx/error.log
```

---

**立即修复**: 运行 `sudo bash scripts/fix-nginx.sh` 🚀

