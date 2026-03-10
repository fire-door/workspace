# iShot 长截图原理与实现分析

## 📋 目录

1. [核心原理](#核心原理)
2. [技术架构](#技术架构)
3. [关键算法](#关键算法)
4. [实现难点](#实现难点)
5. [优化策略](#优化策略)
6. [完整实现](#完整实现)

---

## 核心原理

### 工作流程

```
1. 用户选择截图区域
2. 监听滚动事件
3. 固定频率截取屏幕（10-30 FPS）
4. 图像拼接（核心）
   ├── 重叠区域检测
   ├── 特征点匹配
   └── 无缝合并
5. 输出长图
```

### 两种模式

| 模式 | 手动模式 | 自动模式 |
|------|---------|---------|
| 滚动控制 | 用户操作 | 软件自动 |
| 适用范围 | 所有应用 | 部分应用 |
| 准确度 | 依赖用户 | 高 |
| 速度 | 可变 | 固定 |

---

## 技术架构

### 1. 屏幕捕获

```swift
// 使用 CGWindowListCreateImage 截取屏幕
func captureScreen(rect: CGRect) -> NSImage? {
    guard let cgImage = CGWindowListCreateImage(
        rect,
        .optionOnScreenOnly,
        kCGNullWindowID,
        [.bestResolution, .boundsIgnoreFraming]
    ) else {
        return nil
    }
    
    return NSImage(cgImage: cgImage, size: rect.size)
}
```

**关键技术：**
- `CGWindowListCreateImage` - 高性能截图
- `CGDisplayCreateImage` - 整屏捕获
- 固定帧率控制（10-30 FPS）

### 2. 滚动检测

```swift
// 监听全局滚动事件
NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { event in
    let deltaY = event.scrollingDeltaY
    // 检测滚动方向和速度
}
```

**检测方法：**
- NSEvent 滚轮事件监听
- 滚动方向判断（上/下）
- 速度计算（用于动态调整截图频率）

### 3. 图像拼接（最核心）

这是长截图的技术核心，有三种主要方法：

#### 方法1：模板匹配（Template Matching）

```
原理：
1. 从顶部图像底部提取模板
2. 在底部图像顶部搜索匹配
3. 使用归一化互相关（NCC）计算相似度
```

**优点：** 速度快，实现简单
**缺点：** 对旋转/缩放敏感

#### 方法2：特征点匹配（Feature Matching）

```
原理：
1. 提取两张图的 SIFT/ORB 特征点
2. 匹配特征点对
3. 计算几何变换
4. 确定重叠区域
```

**优点：** 准确度高，鲁棒性强
**缺点：** 计算量大，速度慢

#### 方法3：感知哈希（Perceptual Hash）

```
原理：
1. 计算每行的感知哈希
2. 比对哈希序列
3. 找到匹配位置
```

**优点：** 速度中等，对轻微变化不敏感
**缺点：** 准确度一般

---

## 关键算法

### 1. 归一化互相关（NCC）

最常用的模板匹配算法：

```
NCC = Σ(T(x,y) - T̄) * (I(x,y) - Ī) / 
      √(Σ(T(x,y) - T̄)² * Σ(I(x,y) - Ī)²)

其中：
- T: 模板图像
- I: 搜索区域
- T̄, Ī: 平均值
```

### 2. SIFT 特征提取

```
1. 尺度空间构建（高斯金字塔）
2. 差分高斯（DoG）极值点检测
3. 关键点定位与过滤
4. 方向分配
5. 描述子生成（128维）
```

### 3. 渐变融合

消除拼接痕迹的关键技术：

```swift
// 在接缝处应用渐变混合
func applyGradientBlend(at y: CGFloat, width: CGFloat) {
    let gradient = NSGradient(colors: [
        NSColor.white.withAlphaComponent(0),
        NSColor.white.withAlphaComponent(0.5),
        NSColor.white.withAlphaComponent(0)
    ])
    
    gradient.draw(in: gradientRect, angle: 270)
}
```

---

## 实现难点

### 1. 性能优化

**问题：** 大量图像处理导致卡顿

**解决方案：**
```swift
// 1. 降采样处理
func downsample(_ image: NSImage, scale: CGFloat) -> NSImage {
    // 缩小到 1/scale 后处理
}

// 2. 并行处理
DispatchQueue.global(qos: .userInitiated).async {
    // 图像拼接在后台线程
}

// 3. 增量拼接
// 每捕获一帧立即与上一帧拼接，而不是全部捕获后再拼接
```

### 2. 动态内容处理

**问题：** 页面有动画/视频导致拼接失败

**解决方案：**
```swift
// 检测动态内容
func hasDynamicContent(_ frame1: NSImage, _ frame2: NSImage) -> Bool {
    // 比对同一位置的两帧
    // 如果差异过大，说明有动态内容
}

// 策略：降低该区域的权重或跳过
```

### 3. 内存管理

**问题：** 长图可能非常大

**解决方案：**
```swift
// 1. 使用 ImageIO 逐步写入
func saveIncrementally(image: NSImage, to url: URL) {
    // 使用 CGImageDestination 逐步添加
}

// 2. 压缩中间结果
func compressIntermediateResults() {
    // 保存为 JPEG 而不是 PNG
}

// 3. 及时释放
autoreleasepool {
    // 处理完后立即释放
}
```

### 4. 滚动检测精度

**问题：** 滚动过快或过慢导致拼接失败

**解决方案：**
```swift
// 自适应截图频率
var captureInterval: TimeInterval {
    let speed = abs(lastScrollDelta)
    
    if speed < 50 {
        return 0.1  // 慢速滚动：10 FPS
    } else if speed < 200 {
        return 0.05 // 中速滚动：20 FPS
    } else {
        return 0.03 // 快速滚动：30 FPS
    }
}
```

---

## 优化策略

### 1. 多级缓存

```
内存缓存 → 磁盘缓存 → 最终输出

优点：
- 减少内存占用
- 支持撤销/重做
- 处理中断可恢复
```

### 2. 预测性捕获

```swift
// 预测用户滚动方向
func predictScrollDirection() -> ScrollDirection {
    let recentDeltas = scrollHistory.suffix(5)
    let avgDelta = recentDeltas.reduce(0, +) / CGFloat(recentDeltas.count)
    
    return avgDelta > 0 ? .down : .up
}

// 提前捕获下一帧
```

### 3. 智能拼接

```
if 滚动速度 < 阈值 {
    使用特征点匹配（高精度）
} else {
    使用模板匹配（高速度）
}
```

---

## 完整实现

### 文件结构

```
LongScreenshot/
├── LongScreenshotCapture.swift   # 主控制器
├── ImageStitcher.swift           # 图像拼接算法
├── ScrollDetector.swift          # 滚动检测
├── ScreenCapture.swift           # 屏幕捕获
└── LongScreenshotView.swift      # UI 预览
```

### 使用示例

```swift
// 1. 初始化
let capture = LongScreenshotCapture.shared

// 2. 配置回调
capture.onStateChanged = { state in
    print("状态变化: \(state)")
}

capture.onProgress = { progress in
    print("进度: \(Int(progress * 100))%")
}

capture.onFinished = { image in
    if let result = image {
        // 保存结果
        saveImage(result, to: "~/Desktop/long_screenshot.png")
    }
}

// 3. 开始捕获
let rect = CGRect(x: 0, y: 0, width: 1200, height: 800)
capture.startCapture(in: rect)

// 4. 用户确认后开始截图
capture.beginCapturing()

// 5. 用户停止
capture.stopCapture()
```

---

## iShot 的特殊优化

根据公开信息，iShot 可能在以下方面做了优化：

### 1. 区域识别

```swift
// 自动识别可滚动区域
func findScrollableRegion(in window: NSWindow) -> CGRect? {
    // 使用 Accessibility API 获取滚动视图
    let scrollView = window.accessibilityChildren()?.first {
        $0.role == "AXScrollView"
    }
    
    return scrollView?.frame
}
```

### 2. 自动滚动控制

```swift
// 自动滚动
func autoScroll(window: NSWindow, direction: ScrollDirection) {
    let scrollEvent = CGEvent(
        scrollWheelEvent: nil,
        units: .pixel,
        value1: direction == .down ? -50 : 50,
        value2: 0,
        value3: 0
    )
    
    scrollEvent?.post(tap: .cgSessionEventTap)
}
```

### 3. 智能拼接

```swift
// 检测是否需要拼接
func needsStitching(frame1: NSImage, frame2: NSImage) -> Bool {
    // 快速比对
    let similarity = quickCompare(frame1, frame2)
    return similarity < 0.9  // 如果相似度低于 90%，说明有新内容
}
```

---

## 技术限制

### 1. 不支持的场景

- 横向滚动（部分实现）
- 动态加载内容（无限滚动）
- 视频/动画区域
- 跨桌面截图

### 2. 性能瓶颈

| 场景 | 瓶颈 | 解决方案 |
|------|------|---------|
| 超长页面 | 内存 | 增量写入磁盘 |
| 高分辨率 | CPU | 降采样处理 |
| 快速滚动 | 匹配失败 | 提高帧率 |

---

## 总结

iShot 的长截图功能是一个复杂但精巧的系统，核心在于：

1. **稳定的截图捕获** - CGWindowListCreateImage
2. **精确的滚动检测** - NSEvent 监听
3. **智能的图像拼接** - 模板匹配 + 特征匹配
4. **流畅的用户体验** - 异步处理 + 实时预览

关键算法是**图像拼接**，需要平衡**速度**和**准确度**。

实际生产环境推荐：
- 使用**模板匹配**作为主要方法（快速）
- 在不确定时使用**特征匹配**（准确）
- 应用**渐变融合**消除接缝（美观）

---

## 参考资源

- [CGWindowListCreateImage 文档](https://developer.apple.com/documentation/coregraphics/1455137-cgwindowlistcreateimage)
- [归一化互相关算法](https://en.wikipedia.org/wiki/Cross-correlation#Normalized_cross-correlation)
- [SIFT 特征提取](https://en.wikipedia.org/wiki/Scale-invariant_feature_transform)
- [BetterAndBetter 源码](https://github.com/songhao/BetterAndBetter)
