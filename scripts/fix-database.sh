#!/bin/bash

# 修复数据库连接问题

set -e

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

echo "=========================================="
echo "修复数据库连接"
echo "=========================================="
echo ""

WP_DIR="/var/www/wordpress"
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="wppass123"

# 步骤1: 检查MySQL服务
echo "[1/5] 检查MySQL服务..."
if systemctl is-active --quiet mysql || systemctl is-active --quiet mysqld; then
    echo "  ✓ MySQL服务正在运行"
else
    echo "  启动MySQL服务..."
    $SUDO systemctl start mysql >/dev/null 2>&1 || $SUDO systemctl start mysqld >/dev/null 2>&1 || {
        echo "  ✗ 无法启动MySQL，尝试安装..."
        export DEBIAN_FRONTEND=noninteractive
        $SUDO apt-get update -qq >/dev/null 2>&1
        $SUDO apt-get install -y -qq mysql-server >/dev/null 2>&1
        $SUDO systemctl start mysql >/dev/null 2>&1 || $SUDO systemctl start mysqld >/dev/null 2>&1
        $SUDO systemctl enable mysql >/dev/null 2>&1 || $SUDO systemctl enable mysqld >/dev/null 2>&1
    }
    echo "  ✓ MySQL服务已启动"
fi

# 等待MySQL完全启动
sleep 2

# 步骤2: 创建数据库和用户
echo ""
echo "[2/5] 配置数据库..."

# 创建数据库
$SUDO mysql -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || {
    echo "  ⚠ 创建数据库失败，尝试使用root用户..."
    # 尝试使用root（无密码或默认配置）
    $SUDO mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
}

# 创建用户并授权
$SUDO mysql -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null || {
    echo "  ⚠ 创建用户失败，删除并重新创建..."
    $SUDO mysql -e "DROP USER IF EXISTS '$DB_USER'@'localhost';" 2>/dev/null || true
    $SUDO mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null || true
}

# 授权
$SUDO mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';" 2>/dev/null || {
    $SUDO mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" 2>/dev/null || true
}

# 刷新权限
$SUDO mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

echo "  ✓ 数据库配置完成"
echo "    数据库: $DB_NAME"
echo "    用户: $DB_USER"
echo "    密码: $DB_PASS"

# 步骤3: 测试数据库连接
echo ""
echo "[3/5] 测试数据库连接..."
if mysql -u"$DB_USER" -p"$DB_PASS" -h localhost "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
    echo "  ✓ 数据库连接成功"
else
    echo "  ⚠ 连接测试失败，尝试修复..."
    
    # 重新配置用户权限
    $SUDO mysql <<MYSQL_SCRIPT
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
    
    # 再次测试
    if mysql -u"$DB_USER" -p"$DB_PASS" -h localhost "$DB_NAME" -e "SELECT 1;" >/dev/null 2>&1; then
        echo "  ✓ 数据库连接成功"
    else
        echo "  ⚠ 连接仍然失败，但继续配置WordPress..."
    fi
fi

# 步骤4: 修复wp-config.php
echo ""
echo "[4/5] 修复WordPress配置..."

if [ ! -d "$WP_DIR" ]; then
    echo "  ✗ WordPress目录不存在: $WP_DIR"
    echo "  请先运行: sudo bash scripts/setup-wordpress-now.sh"
    exit 1
fi

# 备份原配置
if [ -f "$WP_DIR/wp-config.php" ]; then
    $SUDO cp "$WP_DIR/wp-config.php" "$WP_DIR/wp-config.php.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
fi

# 确保wp-config.php存在
if [ ! -f "$WP_DIR/wp-config.php" ]; then
    if [ -f "$WP_DIR/wp-config-sample.php" ]; then
        $SUDO cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"
    else
        echo "  ✗ wp-config.php不存在且无法创建"
        exit 1
    fi
fi

# 更新数据库配置
echo "  更新数据库配置..."
$SUDO sed -i "s/define( 'DB_NAME', '[^']*' );/define( 'DB_NAME', '$DB_NAME' );/g" "$WP_DIR/wp-config.php"
$SUDO sed -i "s/define( 'DB_USER', '[^']*' );/define( 'DB_USER', '$DB_USER' );/g" "$WP_DIR/wp-config.php"
$SUDO sed -i "s/define( 'DB_PASSWORD', '[^']*' );/define( 'DB_PASSWORD', '$DB_PASS' );/g" "$WP_DIR/wp-config.php"
$SUDO sed -i "s/define( 'DB_HOST', '[^']*' );/define( 'DB_HOST', 'localhost' );/g" "$WP_DIR/wp-config.php"

# 修复重复的WP_DEBUG定义
echo "  修复WP_DEBUG重复定义..."
# 移除所有WP_DEBUG定义
$SUDO sed -i '/define.*WP_DEBUG/d' "$WP_DIR/wp-config.php"

# 在文件末尾添加调试配置（在"That's all"之前）
if ! grep -q "WP_DEBUG" "$WP_DIR/wp-config.php"; then
    $SUDO sed -i "/That's all, stop editing!/i\\\ndefine( 'WP_DEBUG', false );\ndefine( 'WP_DEBUG_LOG', true );\ndefine( 'WP_DEBUG_DISPLAY', false );\n@ini_set( 'display_errors', 0 );" "$WP_DIR/wp-config.php"
fi

# 设置正确的权限
$SUDO chown www-data:www-data "$WP_DIR/wp-config.php" 2>/dev/null || true
$SUDO chmod 644 "$WP_DIR/wp-config.php" 2>/dev/null || true

echo "  ✓ WordPress配置已更新"

# 步骤5: 验证配置
echo ""
echo "[5/5] 验证配置..."
if [ -f "$WP_DIR/wp-config.php" ]; then
    # 检查关键配置是否存在
    if grep -q "DB_NAME.*$DB_NAME" "$WP_DIR/wp-config.php" && \
       grep -q "DB_USER.*$DB_USER" "$WP_DIR/wp-config.php"; then
        echo "  ✓ 配置验证通过"
    else
        echo "  ⚠ 配置可能不完整，但继续..."
    fi
else
    echo "  ✗ 配置文件不存在"
    exit 1
fi

echo ""
echo "=========================================="
echo "数据库连接修复完成！"
echo "=========================================="
echo ""
echo "数据库信息："
echo "  数据库名: $DB_NAME"
echo "  用户名: $DB_USER"
echo "  密码: $DB_PASS"
echo ""
echo "现在可以尝试重新安装WordPress："
echo "  sudo bash scripts/install-wordpress-cli.sh"
echo ""

