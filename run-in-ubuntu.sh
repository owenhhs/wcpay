#!/bin/bash

# 使用Docker直接运行Ubuntu环境并执行脚本

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "使用Docker启动Ubuntu环境"
echo "=========================================="
echo ""

# 检查Docker是否可用
if ! command -v docker &> /dev/null; then
    echo "✗ Docker未安装或不可用"
    echo "请安装Docker或OrbStack"
    exit 1
fi

echo "✓ Docker可用"
echo ""

# 检查是否有运行的Ubuntu容器
EXISTING_CONTAINER=$(docker ps -a --filter "name=wp-dev-ubuntu" --format "{{.ID}}" | head -1)

if [ -n "$EXISTING_CONTAINER" ]; then
    echo "找到现有容器，使用现有容器..."
    docker start wp-dev-ubuntu >/dev/null 2>&1
    docker exec -it wp-dev-ubuntu bash -c "
        cd /workspace
        echo ''
        echo '✓ 已进入Ubuntu环境'
        echo '项目目录: /workspace'
        echo ''
        if [ -f scripts/assist-test.sh ]; then
            chmod +x scripts/*.sh
            bash scripts/assist-test.sh
        else
            echo '脚本文件不存在'
            echo '当前目录内容:'
            ls -la
        fi
    "
else
    echo "创建新的Ubuntu容器..."
    echo "项目目录: $PROJECT_DIR"
    echo ""
    
    docker run --rm -it \
        --name wp-dev-ubuntu \
        -v "$PROJECT_DIR:/workspace" \
        -w /workspace \
        ubuntu:22.04 \
        bash -c "
            echo '✓ Ubuntu容器已启动'
            echo '正在设置基础环境...'
            apt-get update -qq >/dev/null 2>&1
            apt-get install -y -qq curl wget git >/dev/null 2>&1
            echo '✓ 基础工具已安装'
            echo ''
            echo '=========================================='
            echo 'Ubuntu环境已准备就绪'
            echo '=========================================='
            echo ''
            echo '注意: 这是一个临时容器，用于快速测试'
            echo ''
            echo '如需完整环境，请使用以下方式:'
            echo '  1. 打开OrbStack应用'
            echo '  2. 创建Ubuntu实例'
            echo '  3. 运行: bash scripts/assist-test.sh'
            echo ''
            echo '或者运行环境设置脚本开始完整安装...'
            echo ''
            read -p '是否继续查看脚本？(y/n): ' continue_choice
            if [ \"\$continue_choice\" = \"y\" ] || [ \"\$continue_choice\" = \"Y\" ]; then
                if [ -f scripts/assist-test.sh ]; then
                    echo ''
                    echo '运行协助脚本...'
                    chmod +x scripts/*.sh
                    bash scripts/assist-test.sh
                else
                    echo ''
                    echo '查看可用脚本:'
                    ls -la scripts/*.sh 2>/dev/null | head -10
                fi
            fi
            echo ''
            echo '提示: 要设置完整环境，请使用:'
            echo '  sudo bash scripts/setup-orbstack.sh'
        "
fi

