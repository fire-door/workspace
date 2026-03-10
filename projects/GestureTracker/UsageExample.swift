//
//  UsageExample.swift
//  使用示例
//
//  展示如何使用 GestureTracker 实现轨迹绘制和手势识别
//

import Cocoa

// MARK: - 示例 1: 基本使用

func basicUsage() {
    let tracker = GestureTracker.shared
    
    // 1. 启动追踪（会自动请求辅助功能权限）
    if tracker.startTracking() {
        print("✅ 手势追踪已启动")
    } else {
        print("❌ 需要授权辅助功能权限")
    }
    
    // 2. 配置默认手势
    setupBasicGestures()
    
    // 3. 设置轨迹样式
    tracker.setPathStyle(color: .systemPurple, width: 4)
}

// MARK: - 示例 2: 配置手势动作

func setupBasicGestures() {
    let tracker = GestureTracker.shared
    
    // 方式 1: 使用预定义动作
    tracker.bindAction(.quitApp, toGesture: "circle")
    tracker.bindAction(.screenshotRegion, toGesture: "s")
    tracker.bindAction(.missionControl, toGesture: "up")
    
    // 方式 2: 自定义快捷键
    tracker.bindShortcut(36, modifiers: .command, toGesture: "right")  // Enter
    
    // 方式 3: 启动应用
    tracker.bindAction(.launchApp(bundleIdentifier: "com.apple.Safari"), toGesture: "m")
    
    // 方式 4: 执行 AppleScript
    let script = """
    tell application "Finder"
        empty trash
    end tell
    """
    tracker.bindAppleScript(script, toGesture: "c")
    
    // 方式 5: 执行 Shell 命令
    tracker.bindAction(.shell(command: "say 'Gesture recognized!'"), toGesture: "s")
}

// MARK: - 示例 3: 添加自定义手势模板

func addCustomGestures() {
    let tracker = GestureTracker.shared
    
    // 创建三角形手势模板
    let trianglePoints = generateTrianglePoints()
    let triangleTemplate = GestureTemplate(name: "triangle", points: trianglePoints)
    tracker.addTemplate(triangleTemplate)
    
    // 创建心形手势模板
    let heartPoints = generateHeartPoints()
    let heartTemplate = GestureTemplate(name: "heart", points: heartPoints)
    tracker.addTemplate(heartTemplate)
    
    // 创建星形手势模板
    let starPoints = generateStarPoints()
    let starTemplate = GestureTemplate(name: "star", points: starPoints)
    tracker.addTemplate(starTemplate)
    
    // 绑定动作
    tracker.bindAction(.shortcut(keyCode: 12, modifiers: .command), toGesture: "triangle")
}

// MARK: - 示例 4: 使用代理监听识别结果

class MyGestureDelegate: GestureTrackerDelegate {
    
    func gestureTracker(_ tracker: GestureTracker, didRecognizeGesture name: String, confidence: Double) {
        print("🎯 识别到手势: \(name)")
        print("   置信度: \(String(format: "%.1f", confidence * 100))%")
        
        // 可以在这里添加自定义逻辑
        switch name {
        case "circle":
            showNotification("执行圆形动作")
        case "triangle":
            showNotification("执行三角形动作")
        default:
            break
        }
    }
    
    func gestureTracker(_ tracker: GestureTracker, didDrawPath path: [CGPoint]) {
        // 实时获取轨迹点（可用于实时预览或其他处理）
        if path.count % 10 == 0 {
            print("📍 轨迹点数: \(path.count)")
        }
    }
    
    private func showNotification(_ message: String) {
        let notification = NSUserNotification()
        notification.title = "手势识别"
        notification.informativeText = message
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - 示例 5: 自定义手势生成

func generateTrianglePoints() -> [CGPoint] {
    var points: [CGPoint] = []
    
    // 等边三角形
    let centerX: CGFloat = 0
    let centerY: CGFloat = 0
    let radius: CGFloat = 1
    
    for i in 0..<3 {
        let angle = CGFloat(i) * 2 * .pi / 3 - .pi / 2
        points.append(CGPoint(x: centerX + radius * cos(angle),
                              y: centerY + radius * sin(angle)))
    }
    points.append(points[0]) // 闭合
    
    return points
}

func generateHeartPoints() -> [CGPoint] {
    var points: [CGPoint] = []
    
    for i in 0..<50 {
        let t = CGFloat(i) * 2 * .pi / 50
        
        // 心形参数方程
        let x = 16 * pow(sin(t), 3)
        let y = 13 * cos(t) - 5 * cos(2*t) - 2 * cos(3*t) - cos(4*t)
        
        points.append(CGPoint(x: x / 20, y: y / 20))
    }
    
    return points
}

func generateStarPoints() -> [CGPoint] {
    var points: [CGPoint] = []
    
    let outerRadius: CGFloat = 1
    let innerRadius: CGFloat = 0.4
    
    for i in 0..<10 {
        let angle = CGFloat(i) * .pi / 5 - .pi / 2
        let radius = i % 2 == 0 ? outerRadius : innerRadius
        points.append(CGPoint(x: radius * cos(angle), y: radius * sin(angle)))
    }
    points.append(points[0])
    
    return points
}

// MARK: - 示例 6: 触摸板事件监听（高级）

/*
 如果需要监听触摸板的多点触控事件（而不仅仅是鼠标事件），
 可以使用以下方式：
 
 注意：这需要访问 IOKit 框架
 */

#if canImport(IOKit)
import IOKit

class TouchpadMonitor {
    
    func startMonitoring() {
        // 创建多点触控事件监听
        // 这需要更底层的 IOKit 调用
        // 参考: https://developer.apple.com/documentation/iokit
        
        /*
         // 获取多点触控设备
         let port = IOMasterPort(kIOMasterPortDefault)
         var devices: io_iterator_t = 0
         
         IOServiceGetMatchingServices(
         port,
         IOServiceMatching("AppleMultitouchDevice"),
         &devices
         )
         
         // 监听事件
         // ...
         */
    }
}
#endif

// MARK: - 示例 7: 完整应用流程

class GestureApp {
    
    private let tracker = GestureTracker.shared
    private let delegate = MyGestureDelegate()
    
    func start() {
        // 1. 设置代理
        tracker.delegate = delegate
        
        // 2. 配置手势
        setupBasicGestures()
        addCustomGestures()
        
        // 3. 设置样式
        tracker.setPathStyle(color: .systemBlue, width: 3)
        
        // 4. 启动追踪
        if tracker.startTracking() {
            print("✅ 手势应用已启动")
            print("   按住鼠标右键并拖动来绘制手势")
        }
    }
    
    func stop() {
        tracker.stopTracking()
        print("⏹ 手势追踪已停止")
    }
}
