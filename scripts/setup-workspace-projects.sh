#!/bin/bash
# setup-workspace-projects.sh
# 管理 workspace 中的 git 项目

set -e

WORKSPACE_DIR="$HOME/.openclaw/workspace"
cd "$WORKSPACE_DIR"

echo "=== Workspace 项目管理脚本 ==="
echo ""

# 项目列表（格式：目录名 | Git 仓库地址 | 分支）
PROJECTS=(
  "iBar|https://github.com/JustFavor/iBar.git|dev-claw"
  # 添加更多项目...
  # "other-project|https://github.com/user/repo.git|main"
)

# 1. 检查已存在的项目
echo "📁 检查现有项目..."
for project_info in "${PROJECTS[@]}"; do
  IFS='|' read -r name repo branch <<< "$project_info"

  if [ -d "$name" ]; then
    echo "  ✅ $name - 已存在"

    # 检查是否是 git 仓库
    if [ -d "$name/.git" ]; then
      current_branch=$(cd "$name" && git branch --show-current)
      echo "     当前分支: $current_branch"
    fi
  else
    echo "  ⬜ $name - 不存在"
  fi
done

echo ""

# 2. 询问用户要执行的操作
echo "可选操作:"
echo "  1) 将所有项目转换为 submodule"
echo "  2) 添加新项目作为 submodule"
echo "  3) 更新所有 submodule"
echo "  4) 克隆缺失的项目（不使用 submodule）"
echo "  5) 生成项目列表文档"
echo ""
read -p "请选择操作 (1-5): " choice

case $choice in
  1)
    echo ""
    echo "🔄 转换项目为 submodule..."

    for project_info in "${PROJECTS[@]}"; do
      IFS='|' read -r name repo branch <<< "$project_info"

      if [ -d "$name" ]; then
        # 备份
        echo "  备份 $name..."
        mv "$name" "${name}.backup.$(date +%s)"

        # 添加为 submodule
        echo "  添加 $name 为 submodule..."
        git submodule add -b "$branch" "$repo" "$name" 2>/dev/null || echo "    ⚠️  可能已存在"
      fi
    done

    echo ""
    echo "✅ 转换完成！"
    echo "备份文件保存在各项目的 .backup.* 目录"
    ;;

  2)
    echo ""
    read -p "输入项目名称: " name
    read -p "输入 Git 仓库地址: " repo
    read -p "输入分支名 (默认 main): " branch
    branch=${branch:-main}

    echo ""
    echo "➕ 添加 $name 作为 submodule..."
    git submodule add -b "$branch" "$repo" "$name"
    echo "✅ 添加完成！"
    ;;

  3)
    echo ""
    echo "⬇️  更新所有 submodule..."
    git submodule update --init --recursive
    git submodule foreach git pull origin master
    echo "✅ 更新完成！"
    ;;

  4)
    echo ""
    echo "📥 克隆缺失的项目..."

    for project_info in "${PROJECTS[@]}"; do
      IFS='|' read -r name repo branch <<< "$project_info"

      if [ ! -d "$name" ]; then
        echo "  克隆 $name..."
        git clone -b "$branch" "$repo" "$name"
      fi
    done

    echo "✅ 克隆完成！"
    ;;

  5)
    echo ""
    echo "📝 生成项目列表文档..."

    cat > PROJECTS.md << 'EOF'
# Workspace 项目列表

本工作空间包含以下 Git 项目：

EOF

    for project_info in "${PROJECTS[@]}"; do
      IFS='|' read -r name repo branch <<< "$project_info"

      echo "## $name" >> PROJECTS.md
      echo "" >> PROJECTS.md
      echo "- **仓库**: $repo" >> PROJECTS.md
      echo "- **分支**: $branch" >> PROJECTS.md

      if [ -d "$name" ]; then
        if [ -d "$name/.git" ]; then
          current_branch=$(cd "$name" && git branch --show-current)
          last_commit=$(cd "$name" && git log -1 --format="%h - %s (%ar)")
          echo "- **当前分支**: $current_branch" >> PROJECTS.md
          echo "- **最后提交**: $last_commit" >> PROJECTS.md
        fi
      else
        echo "- **状态**: 未克隆" >> PROJECTS.md
      fi

      echo "" >> PROJECTS.md
    done

    echo "✅ 文档已生成: PROJECTS.md"
    ;;

  *)
    echo "❌ 无效选择"
    exit 1
    ;;
esac

echo ""
echo "完成！"
