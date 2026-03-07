# 🧩 技能推荐库

## 📅 日常效率
- **weather** - 天气查询（✅ 已安装）
- **feishu-doc** - 飞书文档操作（✅ 已安装）
- **feishu-drive** - 飞书云存储（✅ 已安装）
- **feishu-wiki** - 飞书知识库（✅ 已安装）
- **feishu-perm** - 飞书权限管理（✅ 已安装）

## 💻 开发工具
- **skill-creator** - 创建新技能（✅ 已安装）
- **video-frames** - 视频帧提取（✅ 已安装）

## 🏥 系统维护
- **healthcheck** - 安全加固和健康检查（✅ 已安装）

## 🌐 技能市场
- **clawhub** - 技能市场 CLI（✅ 已安装）

## 🔧 其他可用技能（内置）
OpenClaw 内置了 50+ 技能，包括：
- **1password** - 密码管理
- **apple-notes** - Apple 笔记
- **bear-notes** - Bear 笔记
- **notion** - Notion 集成
- **obsidian** - Obsidian 笔记
- **github** - GitHub 操作
- **slack** - Slack 集成
- **spotify-player** - Spotify 控制
- 更多技能见：`/usr/local/node/lib/node_modules/openclaw/skills/`

## 🔧 推荐安装

### 从 ClawHub 安装
```bash
# 搜索技能
openclaw skill search <keyword>

# 安装技能
openclaw skill install <skill-name>
```

### 待安装清单
- [ ] **email** - 邮件处理
- [ ] **calendar** - 日历管理
- [ ] **notes** - 笔记管理
- [ ] **task** - 任务管理

## 📚 技能开发

### 创建自定义技能
```bash
# 使用 skill-creator 技能
# 参考：/usr/local/node/lib/node_modules/openclaw/skills/skill-creator/SKILL.md
```

### 技能结构
```
my-skill/
├── SKILL.md          # 技能定义文件
├── scripts/          # 脚本文件（可选）
└── assets/           # 资源文件（可选）
```

## 🔗 相关链接
- [ClawHub 技能市场](https://clawhub.com)
- [官方技能仓库](https://github.com/openclaw/skills)
- [技能开发文档](https://docs.openclaw.ai/tools/skills)
