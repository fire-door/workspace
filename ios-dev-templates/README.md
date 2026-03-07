# iOS 开发 Agent & Skills 模板

这是一套为 iOS/macOS 开发者准备的 Agent 和 Skills 模板，可以直接应用到你的项目中。

## 📁 目录结构

```
ios-dev-templates/
├── README.md                    # 本文件
│
├── agents/                      # AGENTS.md 模板
│   └── AGENTS.md                # 项目级 Agent 配置
│
└── skills/                      # SKILL.md 技能模板
    ├── swiftui-components/      # SwiftUI 组件开发
    │   └── SKILL.md
    ├── ios-networking/          # 网络层架构
    │   └── SKILL.md
    ├── core-data/               # Core Data 持久化
    │   └── SKILL.md
    ├── uikit-patterns/          # UIKit 开发模式
    │   └── SKILL.md
    └── ios-testing/             # iOS 测试
        └── SKILL.md
```

## 🚀 快速开始

### 1. 使用 AGENTS.md

将 `agents/AGENTS.md` 复制到你的 iOS 项目根目录：

```bash
cp agents/AGENTS.md /path/to/your/project/AGENTS.md
```

然后根据你的项目修改：
- 项目结构
- 技术栈版本
- 构建命令
- 代码风格示例

### 2. 使用 SKILL.md

将需要的 skill 复制到你的项目中：

```bash
# 复制单个 skill
cp -r skills/swiftui-components /path/to/your/project/.clawd/skills/

# 复制所有 skills
cp -r skills/* /path/to/your/project/.clawd/skills/
```

## 📋 模板说明

### AGENTS.md - 项目级配置

| 模块 | 说明 |
|------|------|
| 技术栈 | Swift、Objective-C、SwiftUI、UIKit 等 |
| 项目结构 | MVVM + Coordinator，组件化架构 |
| 常用命令 | xcodebuild、pod、swiftlint |
| 代码风格 | 命名规范、代码组织 |
| 边界规则 | Always / Ask first / Never |

### SKILL.md - 专业技能

| Skill | 用途 |
|-------|------|
| **swiftui-components** | SwiftUI 视图、动画、自定义修饰符 |
| **ios-networking** | 网络层架构、API 客户端、拦截器 |
| **core-data** | 数据持久化、Repository 模式 |
| **uikit-patterns** | UIViewController、MVVM、Coordinator |
| **ios-testing** | 单元测试、UI 测试、Mock 数据 |

## ✏️ 自定义模板

### 修改 AGENTS.md

1. **更新技术栈** — 修改为你项目实际使用的技术
2. **调整项目结构** — 匹配你的目录组织方式
3. **添加构建命令** — 加入你项目的特定命令
4. **更新代码风格** — 用你团队的真实代码示例

### 创建新的 Skill

```bash
# 创建新 skill 目录
mkdir -p skills/my-skill

# 创建 SKILL.md
cat > skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: 技能描述，说明何时使用这个技能
---

# 技能标题

## 内容...
EOF
```

## 🔗 参考资源

### 官方文档

- [OpenClaw 文档](https://docs.openclaw.ai)
- [ClawHub 技能市场](https://clawhub.ai)

### GitHub 示例

- [dyxushuai/agent-skills](https://github.com/dyxushuai/agent-skills) — AGENTS.md 最佳实践
- [Siddhu7007/screen-time-api-agent-skill](https://github.com/Siddhu7007/screen-time-api-agent-skill) — iOS Screen Time API 示例
- [GitHub 官方指南](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) — 2500+ 仓库经验总结

### Agent Skills 规范

- [agentskills.io](https://agentskills.io) — Agent Skills 官方规范

## 📝 最佳实践

### AGENTS.md

1. **命令优先** — 把常用命令放在最前面
2. **示例胜于解释** — 用真实代码展示风格
3. **设置边界** — 明确 Always / Ask first / Never
4. **保持更新** — 随项目演进更新文档

### SKILL.md

1. **单一职责** — 每个 skill 只做一件事
2. **触发条件清晰** — description 中说明何时使用
3. **代码可复制** — 提供完整的代码示例
4. **保持简洁** — SKILL.md 保持在 500 行以内

## 💡 使用建议

### 为现有项目添加

1. 先添加 AGENTS.md，让 AI 了解你的项目
2. 逐步添加 skills，从最常用的开始
3. 根据实际使用调整和优化

### 为新项目创建

1. 使用模板作为起点
2. 根据项目特点修改
3. 随着项目发展持续更新

---

**创建日期:** 2026-03-07
**适用对象:** iOS/macOS 开发者
**维护者:** 小莓派 / Berry
