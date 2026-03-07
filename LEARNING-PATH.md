# 📅 7天掌握 OpenClaw 学习路径

> 从零开始，系统化学习 OpenClaw 个人 AI 助手

---

## 📋 学习路径概览

| 天数 | 主题 | 目标 | 预计时长 |
|------|------|------|----------|
| Day 1 | 认识 OpenClaw | 了解核心概念 | 1-2小时 |
| Day 2 | 环境搭建 | 完成安装配置 | 2-3小时 |
| Day 3 | 渠道集成 | 配置消息平台 | 2-3小时 |
| Day 4 | 技能系统 | 掌握技能使用 | 2-3小时 |
| Day 5 | 工具与自动化 | 自动化工作流 | 2-3小时 |
| Day 6 | 进阶功能 | 高级特性使用 | 2-3小时 |
| Day 7 | 实战项目 | 完成完整项目 | 3-4小时 |

**总时长：** 14-21小时
**学习方式：** 理论 + 实践 + 项目

---

## 🌟 Day 1: 认识 OpenClaw

### 学习目标
- ✅ 了解 OpenClaw 是什么
- ✅ 理解核心概念
- ✅ 知道能做什么

### 学习内容

#### 1.1 OpenClaw 简介（30分钟）
**阅读材料：**
- [官方文档 - 简介](https://docs.openclaw.ai)
- [OpenClaw 101 - 什么是 OpenClaw](https://openclaw101.dev)
- [GitHub README](https://github.com/openclaw/openclaw)

**核心要点：**
- 🦞 个人 AI 助手平台
- 🏠 本地优先，数据在自己手中
- 💬 支持 25+ 消息平台
- 🧩 可扩展技能系统

#### 1.2 核心概念（30分钟）
**关键概念：**
- **Gateway** - 控制平面，管理所有组件
- **Session** - 对话会话，持久化记忆
- **Channel** - 消息渠道（飞书、Telegram等）
- **Skill** - 技能模块，扩展能力
- **Agent** - AI 代理，处理对话

**推荐阅读：**
- [Gateway 架构](https://docs.openclaw.ai/gateway)
- [Session 管理](https://docs.openclaw.ai/sessions)
- [Channel 集成](https://docs.openclaw.ai/channels)

#### 1.3 能力演示（30分钟）
**观看视频：**
- [B站 OpenClaw 演示](https://space.bilibili.com/)
- [YouTube 官方频道](https://youtube.com/@openclaw)

**体验 Demo：**
- 访问 [Discord 社区](https://discord.gg/clawd) 体验机器人

#### 1.4 实践任务
- [ ] 加入 [Discord 社区](https://discord.gg/clawd)
- [ ] 阅读 [OpenClaw 101](https://openclaw101.dev)
- [ ] 思考：我想用 OpenClaw 做什么？

---

## 🚀 Day 2: 环境搭建

### 学习目标
- ✅ 完成 OpenClaw 安装
- ✅ 配置 Gateway
- ✅ 测试基础功能

### 学习内容

#### 2.1 系统要求（15分钟）
**检查清单：**
- [ ] Node.js ≥22
  ```bash
  node --version  # 应该 ≥ v22.0.0
  ```
- [ ] npm 或 pnpm
  ```bash
  npm --version
  # 或
  pnpm --version
  ```
- [ ] 系统权限（非 root）

**安装 Node.js（如果没有）：**
```bash
# macOS/Linux
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# 或使用 nvm
nvm install 22
nvm use 22
```

#### 2.2 安装 OpenClaw（30分钟）
**安装步骤：**
```bash
# 全局安装
npm install -g openclaw@latest

# 验证安装
openclaw --version

# 运行引导程序
openclaw onboard --install-daemon
```

**引导程序会：**
1. 检查系统环境
2. 配置 Gateway
3. 安装守护进程
4. 设置工作空间

#### 2.3 配置模型（30分钟）
**选择模型：**
- 智谱 GLM（推荐，免费额度）
- OpenAI GPT-4
- Claude
- 其他模型

**配置步骤：**
1. 获取 API Key（[智谱开放平台](https://open.bigmodel.cn)）
2. 运行配置向导
   ```bash
   openclaw configure --section models
   ```
3. 或手动编辑配置
   ```bash
   vim ~/.openclaw/openclaw.json
   ```

**配置示例：**
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-5"
      }
    }
  }
}
```

#### 2.4 测试基础功能（30分钟）
**测试命令：**
```bash
# 启动 Gateway
openclaw gateway start

# 检查状态
openclaw status

# 测试对话
openclaw agent --message "你好"

# 诊断检查
openclaw doctor
```

#### 2.5 实践任务
- [ ] 完成 OpenClaw 安装
- [ ] 配置至少一个模型
- [ ] 成功运行 `openclaw doctor`
- [ ] 测试基础对话功能

---

## 💬 Day 3: 渠道集成

### 学习目标
- ✅ 理解渠道概念
- ✅ 配置飞书机器人
- ✅ 测试消息收发

### 学习内容

#### 3.1 渠道概述（15分钟）
**支持的平台：**
- 飞书、钉钉、企业微信
- Telegram、WhatsApp、Signal
- Discord、Slack
- iMessage、IRC、Matrix
- 等等...

**选择建议：**
- 🇨🇳 国内用户：飞书、钉钉
- 🌍 国际用户：Telegram、Discord

#### 3.2 配置飞书机器人（60分钟）
**步骤 1: 创建飞书应用**
1. 访问 [飞书开放平台](https://open.feishu.cn)
2. 创建企业自建应用
3. 获取 App ID 和 App Secret

**步骤 2: 配置权限**
- 接收消息：`im:message`
- 发送消息：`im:message:send_as_bot`
- 获取用户信息：`contact:user.base:readonly`

**步骤 3: 配置 OpenClaw**
```bash
openclaw configure --section channels
```

或手动编辑：
```json
{
  "channels": {
    "feishu": {
      "enabled": true,
      "appId": "cli_xxx",
      "appSecret": "xxx",
      "connectionMode": "websocket"
    }
  }
}
```

**步骤 4: 测试连接**
```bash
# 重启 Gateway
openclaw gateway restart

# 检查状态
openclaw status

# 查看日志
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
```

#### 3.3 DM 配对（30分钟）
**什么是 DM 配对？**
- 保护隐私，防止陌生人骚扰
- 首次对话需要配对码

**配对流程：**
1. 给机器人发送消息
2. 机器人返回配对码
3. 管理员批准配对
   ```bash
   openclaw pairing approve feishu <code>
   ```
4. 配对成功，可以正常对话

#### 3.4 实践任务
- [ ] 创建飞书应用
- [ ] 配置 OpenClaw 飞书渠道
- [ ] 测试消息收发
- [ ] 完成 DM 配对

---

## 🧩 Day 4: 技能系统

### 学习目标
- ✅ 理解技能架构
- ✅ 使用内置技能
- ✅ 安装 ClawHub 技能
- ✅ 创建简单技能

### 学习内容

#### 4.1 技能概述（30分钟）
**什么是技能？**
- 可复用的能力模块
- 定义在 SKILL.md 文件中
- 可以是脚本、工作流、知识库

**技能分类：**
- 内置技能（weather, healthcheck）
- ClawHub 技能（社区共享）
- 自定义技能（自己开发）

#### 4.2 使用内置技能（30分钟）
**weather 技能：**
```bash
# 查询天气
"查询杭州天气"
"明天宁波天气怎么样"
"未来三天安庆天气"
```

**healthcheck 技能：**
```bash
# 系统健康检查
"帮我检查系统安全"
"运行健康检查"
```

#### 4.3 ClawHub 技能市场（30分钟）
**搜索技能：**
```bash
openclaw skill search <keyword>
```

**安装技能：**
```bash
openclaw skill install <skill-name>
```

**推荐技能：**
- email - 邮件处理
- calendar - 日历管理
- notes - 笔记管理

#### 4.4 创建自定义技能（60分钟）
**使用 skill-creator：**
```bash
# 创建技能
"帮我创建一个提醒技能"
```

**手动创建：**
1. 创建目录
   ```bash
   mkdir -p ~/.openclaw/workspace/skills/my-reminder
   ```

2. 创建 SKILL.md
   ```markdown
   ---
   name: my-reminder
   description: 自定义提醒技能
   ---

   # 提醒技能

   当用户要求设置提醒时：
   1. 解析提醒内容和时间
   2. 使用定时任务功能
   3. 在指定时间推送消息
   ```

3. 重启 Gateway
   ```bash
   openclaw gateway restart
   ```

#### 4.5 实践任务
- [ ] 使用 weather 技能查询天气
- [ ] 浏览 ClawHub 技能市场
- [ ] 安装至少一个技能
- [ ] 创建一个简单技能

---

## ⚙️ Day 5: 工具与自动化

### 学习目标
- ✅ 使用浏览器控制
- ✅ 配置定时任务
- ✅ 设置心跳检查

### 学习内容

#### 5.1 浏览器控制（45分钟）
**agent-browser 技能：**
- 自动化浏览器操作
- 网页抓取
- UI 测试

**使用示例：**
```
"帮我打开 GitHub 并搜索 OpenClaw"
"访问某个网站并截图"
"自动填写表单"
```

**注意事项：**
- 需要配置代理（如果在国内）
- 支持无头模式
- 可以保存会话

#### 5.2 定时任务（45分钟）
**Cron 配置：**
```bash
# 添加定时任务
openclaw cron add --name "daily-weather" \
  --schedule "0 7 * * *" \
  --command "查询杭州天气并推送"

# 查看任务列表
openclaw cron list

# 删除任务
openclaw cron remove <task-id>
```

**Cron 格式：**
```
分 时 日 月 周
*  *  *  *  *

示例：
0 7 * * *      # 每天 7:00
*/30 * * * *   # 每 30 分钟
0 9 * * 1-5    # 工作日 9:00
```

#### 5.3 心跳检查（30分钟）
**什么是心跳？**
- 定期检查系统状态
- 主动推送通知
- 后台任务执行

**配置心跳：**
编辑 `HEARTBEAT.md`：
```markdown
# 心跳检查清单

每 4 小时检查：
- [ ] 天气更新
- [ ] 日程提醒
- [ ] 系统状态
```

#### 5.4 实践任务
- [ ] 使用浏览器控制打开网站
- [ ] 配置一个定时天气推送
- [ ] 设置心跳检查

---

## 🎯 Day 6: 进阶功能

### 学习目标
- ✅ 多代理路由
- ✅ Canvas 画布
- ✅ 节点配对

### 学习内容

#### 6.1 多代理路由（45分钟）
**什么是多代理？**
- 不同任务使用不同代理
- 专业代理协作
- 提高效率

**配置示例：**
```json
{
  "agents": {
    "weather-agent": {
      "model": "zai/glm-4.7-flash",
      "skills": ["weather"]
    },
    "code-agent": {
      "model": "zai/glm-5",
      "skills": ["skill-creator", "agent-browser"]
    }
  }
}
```

#### 6.2 Canvas 画布（45分钟）
**什么是 Canvas？**
- 可视化工作空间
- 代理驱动的 UI
- 实时交互

**使用场景：**
- 数据可视化
- 交互式图表
- 实时监控

#### 6.3 节点配对（30分钟）
**什么是节点？**
- iOS/Android 设备
- 远程控制
- 传感器访问

**配对步骤：**
1. 在手机上安装 OpenClaw
2. 扫描配对二维码
3. 批准配对请求

#### 6.4 实践任务
- [ ] 配置多代理路由
- [ ] 尝试 Canvas 画布
- [ ] （可选）配对移动设备

---

## 🎉 Day 7: 实战项目

### 学习目标
- ✅ 完成一个完整项目
- ✅ 综合运用所学知识
- ✅ 分享到社区

### 项目选择

#### 项目 1: 智能天气助手 ⭐⭐
**功能：**
- 每天 7:00 推送天气
- 降温/下雨提醒
- 穿衣建议

**技术：**
- weather 技能
- 定时任务
- 飞书推送

#### 项目 2: 会议纪要助手 ⭐⭐⭐
**功能：**
- 接收会议内容
- 自动格式化
- 创建飞书文档

**技术：**
- feishu-doc 技能
- 文本处理
- 工作流

#### 项目 3: 价格监控机器人 ⭐⭐⭐⭐
**功能：**
- 监控商品价格
- 降价提醒
- 历史价格图表

**技术：**
- agent-browser
- 定时任务
- feishu-bitable

#### 项目 4: 多代理协作系统 ⭐⭐⭐⭐⭐
**功能：**
- 专业代理分工
- 自动任务路由
- 协作完成复杂任务

**技术：**
- sessions_spawn
- subagents
- 自定义路由

### 项目实施

**步骤 1: 需求分析（30分钟）**
- 明确项目目标
- 列出功能清单
- 确定技术方案

**步骤 2: 技能选择（30分钟）**
- 查看可用技能
- 选择合适技能
- （可选）开发自定义技能

**步骤 3: 编码实现（2小时）**
- 配置定时任务
- 编写工作流
- 测试功能

**步骤 4: 优化调试（30分钟）**
- 错误处理
- 性能优化
- 日志记录

**步骤 5: 文档分享（30分钟）**
- 编写使用文档
- 分享到社区
- 收集反馈

### 实践任务
- [ ] 选择一个项目
- [ ] 完成项目开发
- [ ] 编写项目文档
- [ ] 分享到社区

---

## 📚 进阶学习路径

### 完成基础后

#### 深入方向
1. **技能开发** - 创建复杂技能
2. **性能优化** - 提升系统效率
3. **安全加固** - 企业级安全
4. **多语言支持** - i18n 配置

#### 推荐资源
- [官方文档 - 进阶主题](https://docs.openclaw.ai/advanced)
- [OpenClaw 101 - 进阶教程](https://openclaw101.dev/advanced)
- [Discord - 进阶讨论](https://discord.gg/clawd)

#### 社区参与
- 分享你的项目
- 回答新手问题
- 贡献代码/文档
- 参与功能讨论

---

## 🎓 学习建议

### 学习方法
1. **理论 + 实践** - 每学一个概念就动手试试
2. **记录笔记** - 在 `memory/` 目录记录学习心得
3. **遇到问题** - 查 FAQ、搜索日志、问社区
4. **循序渐进** - 不要跳步，打好基础

### 时间安排
- **工作日**：每天 1-2 小时
- **周末**：集中 3-4 小时做项目
- **弹性**：可根据个人情况调整

### 学习资源
- 📖 本地文档：`RESOURCES.md`
- 🧩 技能推荐：`SKILLS.md`
- ❓ 常见问题：`FAQ.md`
- 🎯 实战案例：`USE-CASES.md`

---

## 📝 学习记录模板

在 `memory/` 目录创建每日学习记录：

```markdown
# 2026-03-07 学习记录

## 今日目标
- [ ] 完成 Day 1 学习内容
- [ ] 阅读官方文档
- [ ] 加入社区

## 学习内容
- OpenClaw 核心概念
- Gateway 架构
- Session 管理

## 遇到的问题
1. 问题：xxx
   解决：xxx

## 明日计划
- 完成 Day 2 环境搭建
- 配置 Gateway
```

---

## 🏆 学习里程碑

- ✅ **Day 1-2 完成** - 环境就绪
- ✅ **Day 3-4 完成** - 基础使用
- ✅ **Day 5-6 完成** - 进阶功能
- ✅ **Day 7 完成** - 项目实战
- 🌟 **社区贡献** - 分享经验

---

## 🤝 获取帮助

### 遇到问题？
1. 查看 `FAQ.md`
2. 搜索 [GitHub Issues](https://github.com/openclaw/openclaw/issues)
3. 提问 [Discord 社区](https://discord.gg/clawd)
4. 查看日志 `/tmp/openclaw/openclaw-*.log`

### 推荐社区
- [Discord 中文频道](https://discord.gg/clawd)
- [OpenClaw 101 社区](https://github.com/mengjian-github/openclaw101)

---

**祝你学习愉快！🦞**

**最后更新：** 2026-03-07
**维护者：** 小莓派 (Berry)
