# ❓ 常见问题 FAQ

## 🚀 安装与配置

### Q1: 如何更新 OpenClaw？
```bash
# 更新到最新版本
npm update -g openclaw@latest

# 运行诊断检查
openclaw doctor

# 重启 Gateway
openclaw gateway restart
```

### Q2: Gateway 启动失败怎么办？
**排查步骤：**
1. 检查端口占用
   ```bash
   lsof -i :18789
   # 如果有占用，杀掉进程
   kill -9 <PID>
   ```

2. 检查配置文件
   ```bash
   cat ~/.openclaw/openclaw.json | grep -A 5 "gateway"
   ```

3. 查看日志
   ```bash
   tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log
   ```

4. 重启 Gateway
   ```bash
   openclaw gateway restart
   ```

### Q3: 如何切换模型？
编辑 `~/.openclaw/openclaw.json`：
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "zai/glm-5"  // 改为其他模型
      }
    }
  }
}
```

**可用模型：**
- `zai/glm-5` - 智谱 GLM-5（当前）
- `zai/glm-4.7` - 智谱 GLM-4.7
- `zai/glm-4.7-flash` - 智谱 GLM-4.7 Flash（快速）

---

## 💬 渠道集成

### Q4: 飞书机器人无法接收消息？
**检查清单：**
1. 确认 App ID 和 App Secret 正确
   ```bash
   cat ~/.openclaw/openclaw.json | grep -A 10 "channels"
   ```

2. 检查连接模式（推荐使用 websocket）
   ```json
   "connectionMode": "websocket"
   ```

3. 测试飞书连接
   ```bash
   openclaw doctor
   ```

4. 查看飞书相关日志
   ```bash
   grep "feishu" /tmp/openclaw/openclaw-*.log | tail -20
   ```

### Q5: DM 配对失败怎么办？
**步骤：**
1. 查看配对请求
   ```bash
   openclaw pairing list
   ```

2. 手动批准配对
   ```bash
   openclaw pairing approve feishu <code>
   ```

3. 检查配对状态
   ```bash
   cat ~/.openclaw/pairing.json
   ```

### Q6: 如何配置多个飞书应用？
在 `openclaw.json` 中配置：
```json
{
  "channels": {
    "feishu-app1": {
      "enabled": true,
      "appId": "cli_xxx1",
      "appSecret": "xxx1"
    },
    "feishu-app2": {
      "enabled": true,
      "appId": "cli_xxx2",
      "appSecret": "xxx2"
    }
  }
}
```

---

## 🧩 技能相关

### Q7: 如何安装 ClawHub 技能？
```bash
# 搜索技能
openclaw skill search weather

# 安装技能
openclaw skill install weather

# 列出已安装技能
ls ~/.openclaw/workspace/skills/
```

### Q8: 技能加载失败？
**排查：**
1. 检查 SKILL.md 格式
   ```bash
   cat ~/.openclaw/workspace/skills/<skill-name>/SKILL.md
   ```

2. 确认文件路径正确
   ```bash
   # 技能应该在工作空间的 skills 目录下
   ls -la ~/.openclaw/workspace/skills/
   ```

3. 查看 Gateway 日志
   ```bash
   grep "skill" /tmp/openclaw/openclaw-*.log | tail -20
   ```

### Q9: 如何创建自定义技能？
**步骤：**
1. 使用 skill-creator 技能
2. 创建技能目录
   ```bash
   mkdir -p ~/.openclaw/workspace/skills/my-skill
   ```

3. 创建 SKILL.md 文件
   ```markdown
   ---
   name: my-skill
   description: 我的自定义技能
   ---

   # 技能说明
   这里写技能的具体实现...
   ```

4. 重启 Gateway 加载技能
   ```bash
   openclaw gateway restart
   ```

---

## 🤖 模型与 API

### Q10: API 调用失败？
**检查：**
1. 确认 API Key 有效
   ```bash
   cat ~/.openclaw/openclaw.json | grep "apiKey"
   ```

2. 确认模型 ID 正确
   ```bash
   openclaw status
   ```

3. 查看配额使用情况（登录智谱开放平台）

4. 测试网络连接
   ```bash
   curl -I https://open.bigmodel.cn
   ```

### Q11: 如何配置 API 代理？
编辑 `~/.openclaw/openclaw.json`：
```json
{
  "agents": {
    "defaults": {
      "proxy": {
        "http": "http://127.0.0.1:7890",
        "https": "http://127.0.0.1:7890"
      }
    }
  }
}
```

---

## ⚙️ Gateway 配置

### Q12: Gateway 占用内存过高？
**解决方案：**
1. 检查运行状态
   ```bash
   openclaw gateway status
   ```

2. 重启 Gateway
   ```bash
   openclaw gateway restart
   ```

3. 限制并发数
   ```json
   {
     "agents": {
       "defaults": {
         "maxConcurrent": 2  // 降低并发数
       }
     }
   }
   ```

### Q13: 如何查看 Gateway 日志？
```bash
# 查看今天的日志
tail -f /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# 查看最近 100 行
tail -100 /tmp/openclaw/openclaw-$(date +%Y-%m-%d).log

# 搜索错误
grep "ERROR" /tmp/openclaw/openclaw-*.log | tail -20
```

### Q14: 如何备份配置？
```bash
# 备份配置文件
cp ~/.openclaw/openclaw.json ~/openclaw-backup-$(date +%Y%m%d).json

# 备份工作空间
tar -czf ~/openclaw-workspace-backup.tar.gz -C ~/.openclaw workspace
```

---

## 🌐 网络问题

### Q15: 无法访问外网资源？
**解决方案：**
1. 检查 Clash 是否运行
   ```bash
   curl -I https://www.google.com
   ```

2. 设置环境变量
   ```bash
   export http_proxy=http://127.0.0.1:7890
   export https_proxy=http://127.0.0.1:7890
   ```

3. agent-browser 使用代理
   ```bash
   agent-browser open <url> --proxy "http://127.0.0.1:7890"
   ```

### Q16: WebSocket 连接失败？
**检查：**
1. 防火墙设置
   ```bash
   sudo ufw status
   ```

2. Gateway 绑定地址
   ```json
   {
     "gateway": {
       "bind": "loopback"  // 或 "lan"
     }
   }
   ```

---

## 📅 定时任务

### Q17: 如何设置定时天气推送？
```bash
# 每天早上7点推送天气
openclaw cron add --name "daily-weather" \
  --schedule "0 7 * * *" \
  --command "查询杭州天气并推送到飞书"
```

### Q18: 定时任务不执行？
**排查：**
1. 检查 cron 配置
   ```bash
   openclaw cron list
   ```

2. 查看 cron 日志
   ```bash
   grep "cron" /tmp/openclaw/openclaw-*.log | tail -20
   ```

3. 确认时间格式正确（cron 格式）

---

## 🐛 故障排查

### Q19: openclaw doctor 报告问题？
**常见问题：**
- ❌ Gateway 未运行 → `openclaw gateway start`
- ❌ 配置文件错误 → 检查 JSON 格式
- ❌ 权限问题 → `chmod 644 ~/.openclaw/openclaw.json`
- ❌ 端口占用 → `lsof -i :18789`

### Q20: 完全重置 OpenClaw？
**⚠️ 警告：这将删除所有配置和数据**
```bash
# 停止服务
openclaw gateway stop

# 备份重要数据
cp ~/.openclaw/openclaw.json ~/backup.json

# 删除配置
rm -rf ~/.openclaw

# 重新安装
npm install -g openclaw@latest
openclaw onboard --install-daemon
```

---

## 📚 更多帮助

### 官方资源
- [官方文档](https://docs.openclaw.ai/help/faq)
- [Discord 社区](https://discord.gg/clawd)
- [GitHub Issues](https://github.com/openclaw/openclaw/issues)

### 中文资源
- [OpenClaw 101 FAQ](https://openclaw101.dev/faq)
- [飞书知识库](https://my.feishu.cn/wiki/YkWgwqSchi9xW3kEuZscAm0lnFf)

### 本地资源
- `RESOURCES.md` - 学习资源索引
- `TOOLS.md` - 工具配置速查
- `SKILLS.md` - 技能推荐库

---

**最后更新：** 2026-03-07
**维护者：** 小莓派 (Berry)
