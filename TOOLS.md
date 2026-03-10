# TOOLS.md - 本地配置与工具

技能定义工具_如何_工作。这个文件是_你的_专属配置——你独特设置的内容。

---

## 🌐 网络配置

- **代理配置：** `http_proxy=http://127.0.0.1:7890` / `https_proxy=http://127.0.0.1:7890`
- **访问外网前：** 先检测 Clash 是否正常连接（如 `curl -I https://www.google.com`）
- **agent-browser 使用代理：**
  1. 先关闭旧进程：`agent-browser close`
  2. 加代理参数：`agent-browser open <url> --proxy "http://127.0.0.1:7890"`
  3. 或设置环境变量：`export AGENT_BROWSER_PROXY="http://127.0.0.1:7890"`

---

## 📱 系统信息

- **设备名称：** raspberrypi
- **系统：** Linux 6.12.62+rpt-rpi-v8 (arm64)
- **Node.js：** v24.13.0
- **平台：** Raspberry Pi

---

## 🤖 模型配置

- **当前模型：** zai/glm-5
- **备选模型：** zai/glm-4.7, zai/glm-4.7-flash
- **配置位置：** `~/.openclaw/openclaw.json`

---

## 💬 渠道配置

### 飞书（已配置 ✅）
- **App ID：** cli_a922ed986475dcee
- **连接模式：** websocket
- **群组策略：** open
- **状态：** 运行中

---

## 🧩 已安装技能

### 飞书套件
- feishu-doc（文档操作）
- feishu-drive（云存储）
- feishu-wiki（知识库）
- feishu-perm（权限管理）

### 内置技能
- weather（天气查询）
- healthcheck（安全检查）
- skill-creator（技能创建）
- video-frames（视频处理）
- agent-browser（浏览器自动化）
- find-skills（技能发现）
- clawhub（技能市场）

---

## ⚙️ Gateway 配置

- **端口：** 18789
- **模式：** local
- **绑定：** loopback (127.0.0.1)
- **认证令牌：** ea1f45855d08d68d453d774f37f65f8bf6841d13cfaf8d1c

---

## 🔧 常用命令速查

### Gateway 管理
```bash
openclaw gateway status      # 查看状态
openclaw gateway restart     # 重启服务
openclaw gateway stop        # 停止服务
openclaw gateway start       # 启动服务
```

### 配对管理
```bash
openclaw pairing list        # 查看配对请求
openclaw pairing approve <channel> <code>  # 批准配对
```

### 技能管理
```bash
openclaw skill search <keyword>     # 搜索技能
openclaw skill install <name>       # 安装技能
openclaw skill list                 # 列出已安装技能
```

### 健康检查
```bash
openclaw doctor             # 系统诊断
openclaw status             # 查看状态
```

---

## 📅 定时任务

**当前配置：**

### 每日天气推送 ✅
- **时间：** 每天 7:00 AM
- **脚本：** `~/.openclaw/workspace/scripts/weather-push.sh`
- **日志：** `~/.openclaw/workspace/logs/weather-push.log`
- **推送：** 杭州天气 → 飞书私信

**待添加：**
- [ ] 系统健康检查（每周）

---

## 🐛 故障排查

### 日志位置
- **Gateway 日志：** `/tmp/openclaw/openclaw-2026-03-07.log`
- **配置文件：** `~/.openclaw/openclaw.json`
- **工作空间：** `~/.openclaw/workspace`

### 常见问题
1. **Gateway 无法启动：** 检查端口占用 `lsof -i :18789`
2. **飞书无法接收消息：** 检查 appID/appSecret 配置
3. **技能加载失败：** 检查 SKILL.md 格式

---

## 这里放什么

例如：

- 摄像头名称和位置
- SSH 主机和别名
- TTS 首选语音
- 扬声器/房间名称
- 设备昵称
- 任何环境特定的内容

## 示例

```markdown
### 摄像头

- 客厅 → 主区域，180° 广角
- 前门 → 入口，运动触发

### SSH

- 家庭服务器 → 192.168.1.100，用户：admin

### TTS

- 首选语音："Nova"（温暖，略带英式口音）
- 默认扬声器：厨房 HomePod
```

## 为什么要分开？

技能是共享的。你的设置是你的。分开管理意味着你可以更新技能而不丢失笔记，也可以分享技能而不泄露你的基础设施信息。

---

添加任何有助于你工作的内容。这是你的速查表。
