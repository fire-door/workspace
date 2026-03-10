# LongScreenshot - macOS 长截图实现

类似 iShot 的完整长截图功能实现，包含截图、拼接、预览等所有核心功能。

## 📁 文件列表

### 核心功能

| 文件 | 说明 | 行数 |
|------|------|------|
| **LongScreenshotCapture.swift** | 主控制器 - 截图捕获与状态管理 | 300+ |
| **ImageStitcher.swift** | 图像拼接算法（3种方法） | 500+ |
| **AutoScrollController.swift** | 自动滚动控制 | 250+ |
| **LongScreenshotPreview.swift** | 实时预览视图 | 300+ |
| **LongScreenshotConfig.swift** | 配置管理 | 200+ |
| **ImageProcessingExtensions.swift** | 图像处理工具扩展 | 350+ |
| **UsageExamples.swift** | 完整使用示例 | 300+ |
| **ANALYSIS.md** | 原理分析文档 | - |

## 🎯 核心功能

### 1. 屏幕捕获

```swift
let capture = LongScreenshotCapture.shared
capture.startCapture(in: rect)
capture.beginCapturing()
capture.stopCapture()
```

### 2. 图像拼接（3种算法）

- **模板匹配** - 快速，适合简单场景
- **特征点匹配** - 准确，适合复杂场景
- **感知哈希** - 中等速度和精度
- **混合策略** - 自动选择最佳方法

```swift
let stitcher = ImageStitcher()
stitcher.strategy = .hybrid
let result = stitcher.stitch(top: image1, bottom: image2)
```

### 3. 自动滚动

```swift
let scrollController = AutoScrollController()
scrollController.startScroll(direction: .down, mode: .auto)
```

### 4. 实时预览

```swift
let preview = LongScreenshotPreview.showOnScreen()
preview.updateProgress(frameCount: 10, currentHeight: 2000, preview: image)
```

## 🚀 快速开始

### 方式 1: 最简单的使用

```swift
let capture = LongScreenshotCapture.shared

capture.onFinished = { image in
    if let result = image {
        try? result.save(to: URL(fileURLWithPath: "/tmp/screenshot.png"))
    }
}

let rect = CGRect(x: 0, y: 0, width: 1200, height: 800)
capture.startCapture(in: rect)
capture.beginCapturing()

// 用户滚动后
DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
    capture.stopCapture()
}
```

### 方式 2: 完整应用

```swift
let app = LongScreenshotApp()
app.start()
```

## 📊 技术架构

```
用户操作
    ↓
区域选择 (LongScreenshotPreview)
    ↓
开始捕获 (LongScreenshotCapture)
    ↓
滚动检测 (AutoScrollController)
    ↓
固定频率截图
    ↓
图像拼接 (ImageStitcher)
    ├── 模板匹配
    ├── 特征点匹配
    └── 感知哈希
    ↓
实时预览 (LongScreenshotPreview)
    ↓
保存结果
```

## 🔧 配置选项

```swift
var config = LongScreenshotConfig()

// 截图设置
config.captureInterval = 0.05
config.captureQuality = 0.9

// 拼接设置
config.minOverlap = 50
config.maxOverlap = 200
config.matchThreshold = 0.85
config.stitchStrategy = .hybrid

// 滚动设置
config.autoScroll = true
config.scrollSpeed = 60

// 输出设置
config.outputFormat = .png
config.outputQuality = 1.0

// 应用配置
LongScreenshotConfigManager.shared.update(config)
```

### 预设配置

```swift
.default      // 默认配置
.highQuality  // 高质量（慢）
.fast         // 快速（低质量）
.balanced     // 平衡（推荐）
```

## 📖 核心算法详解

### 1. 图像拼接 - 模板匹配

```swift
// 1. 从顶部图像底部提取模板
let template = extractTemplate(from: top, height: 200)

// 2. 在底部图像顶部搜索
let similarity = computeNCC(template: template, search: bottom)

// 3. 找到最佳匹配位置
if similarity > threshold {
    // 拼接图像
}
```

### 2. 图像拼接 - 特征点匹配

```swift
// 1. 提取特征点
let features1 = extractFeatures(from: top)
let features2 = extractFeatures(from: bottom)

// 2. 匹配特征点
let matches = matchFeatures(features1, features2)

// 3. 计算几何变换
let offset = calculateOffset(from: matches)

// 4. 拼接
return merge(top: top, bottom: bottom, offset: offset)
```

### 3. 渐变融合（消除接缝）

```swift
// 在接缝处应用渐变混合
func applyGradientBlend(at y: CGFloat) {
    let gradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0),
        NSColor.white.withAlphaComponent(0.5),
        NSColor.white.withAlphaComponent(0)
    ])
    gradient.draw(in: gradientRect, angle: 270)
}
```

## ⚡ 性能优化

### 1. 降采样处理

```swift
// 处理前先缩小
let small = image.scaled(by: 0.5)

// 拼接完成后再放大
let result = stitched.resized(to: originalSize)
```

### 2. 并行处理

```swift
DispatchQueue.global(qos: .userInitiated).async {
    // 图像拼接在后台线程
    self.stitchFrames()
}
```

### 3. 增量拼接

```swift
// 每捕获一帧立即拼接，而不是全部捕获后再拼接
func captureFrame() {
    let frame = captureScreen()
    
    if let lastFrame = frames.last {
        let merged = stitch(top: lastFrame, bottom: frame)
        frames[frames.count - 1] = merged
    } else {
        frames.append(frame)
    }
}
```

### 4. 内存管理

```swift
// 压缩中间结果
let compressed = image.compressed(to: 5 * 1024 * 1024)  // 5MB

// 及时释放
autoreleasepool {
    // 处理大量图像
}
```

## 🐛 调试技巧

### 1. 性能监控

```swift
let monitor = PerformanceMonitor.shared
monitor.start()

monitor.checkpoint("捕获开始")
// ... 操作
monitor.checkpoint("拼接完成")

print(monitor.report())
```

### 2. 保存调试图像

```swift
#if DEBUG
image.debugSave(name: "frame_1")
#endif
```

### 3. 启用调试模式

```swift
var config = LongScreenshotConfig()
config.debugMode = true
```

## 📝 注意事项

### 1. 辅助功能权限

需要在 `Info.plist` 添加：

```xml
<key>NSAppleEventsUsageDescription</key>
<string>需要此权限来监听滚动事件</string>
```

并在首次运行时授权。

### 2. 不支持的场景

- ❌ 横向滚动（部分实现）
- ❌ 无限滚动页面
- ❌ 动态加载内容
- ❌ 视频播放区域
- ❌ 跨桌面截图

### 3. 最佳实践

- ✅ 滚动速度适中（不要太快）
- ✅ 选择纯滚动区域（避免标题栏）
- ✅ 关闭页面动画
- ✅ 使用 `hybrid` 拼接策略

## 🔗 相关资源

- [iShot 官网](https://shotapp.cn)
- [CGWindowListCreateImage 文档](https://developer.apple.com/documentation/coregraphics/1455137-cgwindowlistcreateimage)
- [图像拼接算法](https://docs.opencv.org/4.x/d1/d46/group__stitching.html)

## 📄 License

MIT License - 可自由使用和修改

---

## 🎉 完整示例

查看 `UsageExamples.swift` 获取更多使用示例。

集成到你的项目：

1. 复制需要的 `.swift` 文件到项目
2. 配置 `Info.plist` 权限
3. 调用 `LongScreenshotApp().start()`

就这么简单！🚀
