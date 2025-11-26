#!/bin/bash

# 处理目录已存在的情况

echo "=========================================="
echo "处理现有目录"
echo "=========================================="
echo ""

cd ~

if [ -d "wcpay" ]; then
    echo "发现现有 wcpay 目录"
    echo ""
    echo "目录内容:"
    ls -la wcpay/ | head -10
    echo ""
    
    echo "选择操作："
    echo "1. 删除现有目录并重新克隆（推荐）"
    echo "2. 进入现有目录并更新"
    echo "3. 重命名现有目录然后克隆新的"
    read -p "选择 (1/2/3): " choice
    
    case $choice in
        1)
            echo ""
            echo "删除现有目录..."
            rm -rf wcpay
            echo "✓ 目录已删除"
            echo ""
            echo "重新克隆项目..."
            git clone https://github.com/owenhhs/wcpay.git
            cd wcpay
            ;;
        2)
            echo ""
            echo "进入现有目录..."
            cd wcpay
            
            # 检查是否是git仓库
            if [ -d ".git" ]; then
                echo "更新现有仓库..."
                git pull origin main || {
                    echo "更新失败，尝试重新克隆..."
                    cd ..
                    rm -rf wcpay
                    git clone https://github.com/owenhhs/wcpay.git
                    cd wcpay
                }
            else
                echo "不是git仓库，删除并重新克隆..."
                cd ..
                rm -rf wcpay
                git clone https://github.com/owenhhs/wcpay.git
                cd wcpay
            fi
            ;;
        3)
            echo ""
            BACKUP_NAME="wcpay-backup-$(date +%s)"
            echo "重命名现有目录为: $BACKUP_NAME"
            mv wcpay "$BACKUP_NAME"
            echo "✓ 已重命名"
            echo ""
            echo "克隆新项目..."
            git clone https://github.com/owenhhs/wcpay.git
            cd wcpay
            ;;
    esac
else
    echo "目录不存在，直接克隆..."
    git clone https://github.com/owenhhs/wcpay.git
    cd wcpay
fi

echo ""
echo "✓ 项目目录已准备好"
echo "当前目录: $(pwd)"
echo ""

# 检查scripts目录
if [ -d "scripts" ] && [ -f "scripts/assist-test.sh" ]; then
    echo "✓ scripts目录存在"
    echo ""
    echo "设置权限..."
    chmod +x scripts/*.sh
    echo "✓ 权限设置完成"
    echo ""
    echo "运行协助脚本..."
    echo "=========================================="
    echo ""
    bash scripts/assist-test.sh
else
    echo "✗ scripts目录不存在或文件不完整"
    echo ""
    echo "当前目录内容:"
    ls -la
    echo ""
    echo "scripts目录内容:"
    ls -la scripts/ 2>/dev/null || echo "scripts目录不存在"
fi

