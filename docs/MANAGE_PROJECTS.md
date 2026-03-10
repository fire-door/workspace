# Workspace 项目管理指南

## 问题说明

当 workspace 中有克隆的 Git 项目时（如 iBar），这些项目有自己的 `.git` 目录，不会被提交到 workspace 仓库。

## 解决方案：使用 Git Submodule

### 什么是 Submodule？

Submodule（子模块）允许你将一个 Git 仓库作为另一个 Git 仓库的子目录，同时保持提交的独立性。

### 优点

- ✅ workspace 可以追踪子项目的版本
- ✅ 子项目保持独立的 Git 历史
- ✅ 可以锁定子项目的特定版本
- ✅ 团队成员可以同步项目

---

## 操作步骤

### 方案一：自动脚本（推荐）

```bash
cd ~/.openclaw/workspace
chmod +x scripts/setup-workspace-projects.sh
./scripts/setup-workspace-projects.sh
```

选择操作 1，自动转换所有项目为 submodule。

---

### 方案二：手动操作

#### 1. 将 iBar 转换为 Submodule

```bash
cd ~/.openclaw/workspace

# 1. 备份 iBar
cp -r iBar ../iBar.backup

# 2. 从 .gitignore 移除 iBar
# 编辑 .gitignore，删除或注释掉 "iBar/" 这一行

# 3. 删除现有的 iBar 目录
rm -rf iBar

# 4. 添加 iBar 作为 submodule
git submodule add -b dev-claw https://github.com/JustFavor/iBar.git iBar

# 5. 提交更改
git add .gitmodules iBar
git commit -m "chore: 将 iBar 转换为 submodule"

# 6. 推送到远程
git push
```

---

#### 2. 以后克隆其他项目

**方式 A: 直接用 submodule 添加**
```bash
cd ~/.openclaw/workspace

# 添加新项目作为 submodule
git submodule add -b main https://github.com/user/repo.git projects/repo-name

# 提交
git add .gitmodules projects/repo-name
git commit -m "chore: 添加 repo-name submodule"
git push
```

**方式 B: 使用脚本添加**
```bash
./scripts/setup-workspace-projects.sh
# 选择操作 2
```

---

## 日常使用

### 克隆 workspace 到新机器

```bash
# 克隆主仓库
git clone https://github.com/JustFavor/workspace.git
cd workspace

# 初始化并更新所有 submodule
git submodule update --init --recursive
```

### 更新某个 submodule

```bash
# 更新 iBar
cd iBar
git pull origin dev-claw

# 回到 workspace，提交更新的版本
cd ..
git add iBar
git commit -m "chore: 更新 iBar 到最新版本"
git push
```

### 更新所有 submodule

```bash
# 方式 1: 简单更新
git submodule foreach git pull origin master

# 方式 2: 使用脚本
./scripts/setup-workspace-projects.sh
# 选择操作 3
```

---

## 管理 Submodule

### 查看 submodule 状态

```bash
git submodule status
```

### 删除 submodule

```bash
# 1. 取消注册
git submodule deinit -f iBar

# 2. 删除
rm -rf .git/modules/iBar
git rm -f iBar

# 3. 提交
git commit -m "chore: 移除 iBar submodule"
```

---

## 替代方案

### 方案三：使用 PROJECTS.md 记录

如果你不想用 submodule，可以：

1. 在 .gitignore 排除所有克隆的项目
2. 创建 `PROJECTS.md` 记录需要克隆的项目
3. 用脚本自动克隆

**优点**: 最简单
**缺点**: workspace 不追踪子项目版本

---

## 当前 Workspace 中的项目

| 项目 | 路径 | 状态 | Git 仓库 |
|------|------|------|---------|
| iBar | `iBar/` | Git 仓库 | https://github.com/JustFavor/iBar |
| GestureTracker | `projects/GestureTracker/` | 普通目录 | - |
| LongScreenshot | `projects/LongScreenshot/` | 普通目录 | - |

---

## 推荐

**对于你的情况，我推荐**:

1. **iBar** → 转换为 Submodule（需要追踪版本）
2. **GestureTracker/LongScreenshot** → 直接提交（你自己创建的，不是 git 仓库）

这样：
- workspace 可以追踪 iBar 的版本
- 你的项目代码也备份到 GitHub
- 管理清晰

---

## 快速开始

```bash
# 1. 运行脚本
cd ~/.openclaw/workspace
./scripts/setup-workspace-projects.sh

# 2. 选择操作 1（转换项目为 submodule）

# 3. 完成后提交
git add .
git commit -m "chore: 管理 workspace 中的 git 项目"
git push
```
