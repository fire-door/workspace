# MEMORY.md - 长期记忆

## 项目与技术

### Xcode MCP 配置（2026-03-08）

**项目地址：** https://github.com/lapfelix/XcodeMCP

**功能：** 通过 MCP（Model Context Protocol）控制 Xcode，实现 AI 辅助开发

**推荐配置：** Apple 官方 MCP + XcodeMCP sidekick 模式
```bash
# 启用 Apple 官方 Xcode MCP（Xcode > Settings > Intelligence > MCP）
# 添加 sidekick 模式
claude mcp add-json xcodemcp '{
  "command": "npx",
  "args": ["-y", "xcodemcp@latest", "--sidekick-only"]
}'
```

**主要功能：**
- 项目管理（打开/关闭项目、管理工作空间）
- 构建操作（构建、测试、运行、调试）
- XCResult 分析（测试结果、UI 层级、截图提取）

**CLI 工具：** `xcodecontrol`
```bash
npm install -g xcodemcp
xcodecontrol health-check
xcodecontrol build --xcodeproj MyApp.xcodeproj --scheme MyApp
```

**系统要求：** macOS + Xcode + Node.js 18+

---

## 系统配置

### 神卓互联内网穿透（2026-03-07）

**安装路径：** `/usr/local/shenzhuo/`

**服务管理命令：**
```bash
# 启动服务
sudo systemctl start shenzhuo

# 重启服务
sudo systemctl restart shenzhuo

# 停止服务
sudo systemctl stop shenzhuo

# 查看日志
sudo journalctl -u shenzhuo -n 50
```

**注意事项：**
- 服务以 root 权限运行
- 客户端日志位置：`/usr/local/shenzhuo/log/`
- 修改账号密码：编辑 `/etc/systemd/system/shenzhuo.service` 文件中的 `ExecStart` 行，然后执行 `systemctl daemon-reload && systemctl restart shenzhuo`

---

## 经验教训

### 停止 Clash 代理导致系统断连（2026-03-09）

**问题：** 停止 Clash 进程后，系统环境变量 `http_proxy` 和 `https_proxy` 仍指向 `127.0.0.1:7890`，但端口已无监听，导致依赖代理的服务无法连接网络，最终系统不稳定重启。

**正确操作：**
```bash
# 停止 Clash 前，先清除代理环境变量
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# 然后再 kill 进程
kill <clash_pid>
```

**恢复操作：** Clash 已配置自动启动（systemd 或其他方式），重启后会自动恢复。

**相关配置：**
- Clash 路径：`/home/gh/clash/clash`
- 配置目录：`/home/gh/.config/clash`
- 代理端口：7890

---

## 重要事件

### 2026-03-08 伊朗局势
- 美以与伊朗军事冲突持续升级
- 主要动态：以军轰炸德黑兰燃料设施、伊朗"真实承诺4"第27轮行动
- 使用 agent-browser 成功搜索并获取新闻信息

---

### 2026-03-10 LLDB Debug MCP 项目

**项目路径：** `~/clawd/lldb-debugger/`

**目的：** 突破 Apple MCP 仅支持模拟器的限制，实现 iOS 真机调试自动化

**功能：**
- 真机断点设置/删除/条件断点
- 执行控制（继续、单步、运行到指定位置）
- 变量读取/修改/表达式执行
- 调用栈查看和切换
- MCP 协议支持（AI 可直接调用）

**技术栈：** Python + LLDB Python API + MCP

**使用方式：**
```bash
# Claude Desktop 配置
"mcpServers": {
  "lldb-debug": {
    "command": "python3",
    "args": ["/home/gh/clawd/lldb-debugger/mcp_server/server.py"]
  }
}
```

**对比 Apple MCP：**
| 特性 | Apple MCP | LLDB Debug MCP |
|------|-----------|----------------|
| 真机支持 | ❌ | ✅ |
| 模拟器支持 | ✅ | ✅ |
| 条件断点 | ❓ | ✅ |
| 变量修改 | ❓ | ✅ |

---

### 2026-03-10 macOS 效率工具分析

#### BetterAndBetter 轨迹绘制分析

**仓库地址：** https://github.com/songhao/BetterAndBetter

**功能：** macOS 触摸板/鼠标手势识别应用

**核心实现：**
- **事件监听**：CGEventTap 监听全局鼠标/触摸事件
- **轨迹绘制**：NSBezierPath 绘制贝塞尔曲线
- **手势识别**：$1 Unistroke Recognizer 算法
  - 重采样到 64 点
  - 旋转/缩放/平移归一化
  - 模板匹配 + 黄金分割搜索
- **权限要求**：辅助功能权限

**实现代码位置：** `~/.openclaw/workspace/projects/GestureTracker/`

**关键文件：**
- GestureTracker.swift（300+ 行）
- ImageStitcher.swift（500+ 行）
- GestureRecognizer.swift（$1 算法实现）

---

#### iShot 长截图原理分析

**功能：** macOS 滚动截图工具

**核心原理：**
1. **固定频率截图**（10-30 FPS）
2. **图像拼接**（3 种算法）：
   - 模板匹配（最快）
   - 特征点匹配（最准）
   - 感知哈希（中等）
3. **渐变融合**消除接缝

**技术栈：**
- CGWindowListCreateImage 截图
- NCC 归一化互相关
- SIFT 特征点提取
- NSImage 图像处理

**实现代码位置：** `~/.openclaw/workspace/projects/LongScreenshot/`

**关键发现：**
- 截图频率过高会触发录屏提示
- 动态内容（视频/动画）会导致拼接失败
- 超长页面需要增量写入磁盘避免内存溢出

---

#### iBar macOS 26 适配

**仓库地址：** https://github.com/JustFavor/iBar

**分支：** dev-claw

**问题：** macOS 26 菜单栏完全透明，导致图标截图失败

**解决方案：**
1. **像素级透明度检测**（采样 1000 点）
2. **macOS 26 适配**（版本检测）
3. **截图增强**（重试机制）
4. **Alpha 通道处理**（添加背景色）
5. **动态坐标计算**（适配菜单栏高度）

**新增代码：**
- MacOS26Compatibility.h/m（789 行）
- MacOS26CompatibilityTests.m（321 行，28 个测试用例）

**文档：** 60,130 字技术文档

**提交记录：** 9 次提交到 dev-claw 分支

**关键优化点：**
- P0：透明度检测 + macOS 26 适配
- P1：坐标计算 + Alpha 通道处理
- P2：重试机制 + 版本检测

**待办：**
- ⬜ 用户测试 macOS 26 优化代码
- ⬜ 根据反馈调整实现
- ⬜ 集成到主分支
- ⬜ 发布 v1.3.6

---

*最后更新：2026-03-11 23:25*

---

### 2026-03-11 CleanApps Swift 重构项目

**项目地址：** https://github.com/JustFavor/CleanApps

**分支：** `ai_claw`

**目的：** 将 OC 代码重构为 Swift，XIB UI 改为纯代码，解决 App Store 重复应用拒绝问题

#### 已完成工作

**1. 基础架构（17 个 Swift 文件，~145KB）**
- Model 层：AppModel, FileItem, FileGroup
- Manager 层：PermissionManager, ScanManager, UninstallManager
- ViewModel 层：UninstallViewModel
- Controllers：MainViewController, AppListViewController, UninstallDetailViewController, PermissionGuideViewController, SettingsViewController
- Views：BaseView, BaseViewController, AppCellView, EmptyStateView, SizeInfoView

**2. 核心功能**
- ✅ 应用扫描（系统 + 目录枚举）
- ✅ 文件关联扫描（缓存、偏好设置等）
- ✅ 批量卸载
- ✅ 拖放卸载
- ✅ 权限检查和引导（不触发系统提示）
- ✅ 进度跟踪

**3. UI 功能**
- ✅ 搜索/过滤
- ✅ 排序（大小升序/降序、名称、日期）
- ✅ 默认排序：按大小升序（从小到大）
- ✅ 多选
- ✅ 详情页（OutlineView 展示文件）
- ✅ 加载状态显示
- ✅ Cell 右键菜单（在 Finder 中显示、查看关联文件、卸载）
- ✅ Cell 版本号显示
- ✅ 设置窗口（权限设置、通用设置、关于）

**4. AppDelegate 集成**
- ✅ 导入 Swift 头文件 (CleanApps-Swift.h)
- ✅ 使用 MainViewController 替代旧 OC 窗口
- ✅ 保留菜单栏、守护进程通信等功能

#### 技术要点

**权限检测（避免触发系统提示）：**
```swift
// 安全检测（不触发提示）
func getFullDiskAuthorizationStatus() -> FullDiskAuthorizationStatus

// 真实检测（会触发提示，仅在用户主动操作时调用）
func checkRealFullDiskAccessStatus() -> FullDiskAuthorizationStatus
```

**排序修复：**
- 合并 `filterApps()` 和 `sortApps()` 为 `filterAndSortApps()`
- 确保先过滤再排序，避免顺序错误

**目录结构：**
```
CleanApps/Classes/Swift/
├── Models/
├── Managers/
├── ViewModels/
├── Controllers/
├── Views/
│   ├── Base/
│   ├── Cells/
│   └── Components/
└── Utils/
```

#### 待完成

- ⬜ 完善 Helper 通信（XPC/CFNotification）
- ⬜ 完善本地化字符串
- ⬜ 测试和修复 bug
- ⬜ 移除废弃 OC 代码
- ⬜ 移除 XIB 文件
