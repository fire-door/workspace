# GestureTracker 使用指南

类似 BetterAndBetter 的 macOS 轨迹绘制与手势识别实现。

## 📁 文件结构

```
GestureTracker/
├── README.md                     # 项目说明
├── Info.plist                    # 应用配置
│
├── Swift 实现/
│   ├── GestureTracker.swift      # 核心控制器
│   ├── GestureOverlayView.swift  # 轨迹绘制视图
│   ├── GestureRecognizer.swift   # 手势识别器 ($1算法)
│   ├── GestureTracker+Bindings.swift  # 动作绑定扩展
│   ├── AppDelegate.swift         # 应用入口
│   └── UsageExample.swift        # 使用示例
│
└── Objective-C 实现/
    ├── GestureTracker.h          # 头文件
    └── GestureTracker.m          # 实现文件
```

## 🚀 快速开始

### Swift 版本

```swift
import Cocoa

// 1. 获取单例
let tracker = GestureTracker.shared

// 2. 配置手势动作
tracker.bindAction(.shortcut(keyCode: 12, modifiers: .command), toGesture: "circle")

// 3. 启动追踪
if tracker.startTracking() {
    print("手势追踪已启动，按住右键绘制手势")
}
```

### Objective-C 版本

```objc
#import "GestureTracker.h"

// 1. 获取单例
BABGestureTracker *tracker = [BABGestureTracker sharedTracker];

// 2. 配置手势动作
BABGestureAction *action = [BABGestureAction shortcutWithKeyCode:12 modifiers:NSEventModifierFlagCommand];
[tracker bindAction:action toGesture:@"circle"];

// 3. 启动追踪
if ([tracker startTracking]) {
    NSLog(@"手势追踪已启动");
}
```

## 🎯 核心功能

### 1. 事件监听

使用 `CGEventTap` 监听全局鼠标事件：

```swift
// 监听的事件类型
let eventsToWatch: CGEventMask = 
    (1 << CGEventType.mouseDown.rawValue) |
    (1 << CGEventType.mouseUp.rawValue) |
    (1 << CGEventType.mouseDragged.rawValue)
```

### 2. 轨迹绘制

创建全屏透明窗口，使用 `NSBezierPath` 绘制轨迹：

```swift
class GestureOverlayView: NSView {
    var pathColor: NSColor = .systemBlue
    var lineWidth: CGFloat = 3.0
    
    override func draw(_ dirtyRect: NSRect) {
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.move(to: points[0])
        
        for point in points.dropFirst() {
            path.line(to: point)
        }
        
        pathColor.setStroke()
        path.stroke()
    }
}
```

### 3. 手势识别

使用 **$1 Unistroke Recognizer** 算法：

1. **重采样** - 将轨迹统一到 64 个点
2. **旋转归一化** - 旋转到统一方向
3. **缩放归一化** - 缩放到固定正方形
4. **平移归一化** - 移动到原点
5. **模板匹配** - 与预定义模板比对

### 4. 动作执行

支持多种动作类型：

```swift
// 快捷键
GestureAction.shortcut(keyCode: 12, modifiers: .command)

// AppleScript
GestureAction.applescript(source: "tell application \"Finder\" to activate")

// Shell 命令
GestureAction.shell(command: "say 'Gesture recognized'")

// 启动应用
GestureAction.launchApp(bundleIdentifier: "com.apple.Safari")
```

## 🔧 配置选项

### 轨迹样式

```swift
// 设置颜色和线宽
tracker.setPathStyle(color: .systemPurple, width: 4)
```

### 识别阈值

```swift
// 调整置信度阈值 (0.0 - 1.0)
recognizer.confidenceThreshold = 0.75
```

### 触发按键

```swift
// 默认右键，可改为其他按键
tracker.triggerButton = .right
```

## 📝 添加自定义手势

### Swift

```swift
// 创建手势模板
let trianglePoints = generateTrianglePoints()
let template = GestureTemplate(name: "triangle", points: trianglePoints)

// 添加到识别器
tracker.addTemplate(template)

// 绑定动作
tracker.bindAction(.shortcut(keyCode: 36, modifiers: .command), toGesture: "triangle")
```

### Objective-C

```objc
// 创建手势模板
NSMutableArray *points = [NSMutableArray array];
for (int i = 0; i < 3; i++) {
    CGFloat angle = i * 2 * M_PI / 3 - M_PI / 2;
    CGPoint point = CGPointMake(cos(angle), sin(angle));
    [points addObject:[NSValue valueWithPoint:point]];
}

BABGestureTemplate *template = [[BABGestureTemplate alloc] initWithName:@"triangle" points:points];

// 添加到识别器
[tracker addTemplate:template];

// 绑定动作
BABGestureAction *action = [BABGestureAction shortcutWithKeyCode:36 modifiers:NSEventModifierFlagCommand];
[tracker bindAction:action toGesture:@"triangle"];
```

## ⚠️ 注意事项

### 1. 辅助功能权限

应用需要用户授权辅助功能权限才能监听全局事件：

```swift
let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
```

在 `Info.plist` 中添加权限说明。

### 2. 沙盒限制

全局事件监听需要关闭 App Sandbox。在 Xcode 项目设置中：
- 取消勾选 "App Sandbox"
- 或添加特定的 entitlements

### 3. 性能优化

- 轨迹点采样：每 5-10 像素采样一个点
- 使用 Douglas-Peucker 算法简化路径
- 避免在主线程进行复杂的识别计算

## 🔗 参考资源

- [$1 Unistroke Recognizer](https://depts.washington.edu/acelab/proj/dollar/index.html)
- [CGEventTap 文档](https://developer.apple.com/documentation/coregraphics/cgeventtap)
- [BetterAndBetter 源码](https://github.com/songhao/BetterAndBetter)

## 📄 License

MIT License
