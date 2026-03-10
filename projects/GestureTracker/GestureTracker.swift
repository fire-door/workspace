//
//  GestureTracker.swift
//  GestureTracker - macOS轨迹绘制与手势识别
//
//  核心功能：监听全局鼠标/触摸事件，绘制轨迹，识别手势
//

import Cocoa
import Carbon

// MARK: - 手势动作类型
enum GestureAction {
    case shortcut(keyCode: Int, modifiers: NSEvent.ModifierFlags)
    case applescript(source: String)
    case shell(command: String)
    case launchApp(bundleIdentifier: String)
    case none
}

// MARK: - 手势识别代理
protocol GestureTrackerDelegate: AnyObject {
    func gestureTracker(_ tracker: GestureTracker, didRecognizeGesture name: String, confidence: Double)
    func gestureTracker(_ tracker: GestureTracker, didDrawPath path: [CGPoint])
}

// MARK: - 主控制器
class GestureTracker {
    
    // 单例
    static let shared = GestureTracker()
    
    // 代理
    weak var delegate: GestureTrackerDelegate?
    
    // 状态
    private(set) var isTracking = false
    private(set) var isDrawing = false
    
    // 轨迹点
    private var pathPoints: [CGPoint] = []
    
    // 触发按键（默认右键）
    var triggerButton: NSEvent.EventButton = .right
    
    // 手势识别器
    private let recognizer = GestureRecognizer()
    
    // 轨迹绘制窗口
    private var overlayWindow: NSWindow?
    private var overlayView: GestureOverlayView?
    
    // 事件监听
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    // 手势动作映射
    private var gestureActions: [String: GestureAction] = [:]
    
    // MARK: - 初始化
    
    private init() {
        setupOverlayWindow()
        loadGestureTemplates()
    }
    
    // MARK: - 公开方法
    
    /// 开始监听
    func startTracking() -> Bool {
        guard !isTracking else { return true }
        
        // 检查辅助功能权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            print("⚠️ 需要辅助功能权限")
            return false
        }
        
        // 创建事件监听
        setupEventTap()
        isTracking = true
        return true
    }
    
    /// 停止监听
    func stopTracking() {
        guard isTracking else { return }
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            }
            CFMachPortInvalidate(tap)
        }
        
        eventTap = nil
        runLoopSource = nil
        isTracking = false
    }
    
    /// 绑定手势动作
    func bindAction(_ action: GestureAction, toGesture name: String) {
        gestureActions[name] = action
    }
    
    /// 添加手势模板
    func addTemplate(_ template: GestureTemplate) {
        recognizer.addTemplate(template)
    }
    
    /// 设置轨迹样式
    func setPathStyle(color: NSColor, width: CGFloat) {
        overlayView?.pathColor = color
        overlayView?.lineWidth = width
    }
    
    // MARK: - 私有方法
    
    private func setupOverlayWindow() {
        // 创建全屏透明窗口
        let screen = NSScreen.main!
        let rect = screen.frame
        
        overlayWindow = NSWindow(
            contentRect: rect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow?.level = .screenSaver
        overlayWindow?.backgroundColor = .clear
        overlayWindow?.ignoresMouseEvents = true
        overlayWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 创建绘制视图
        overlayView = GestureOverlayView(frame: rect)
        overlayWindow?.contentView = overlayView
    }
    
    private func setupEventTap() {
        // 监听的事件类型
        let eventsToWatch: CGEventMask = 
            (1 << CGEventType.mouseDown.rawValue) |
            (1 << CGEventType.mouseUp.rawValue) |
            (1 << CGEventType.mouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue)
        
        // 创建事件回调
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let tracker = Unmanaged<GestureTracker>.fromOpaque(refcon).takeUnretainedValue()
            tracker.handleEvent(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }
        
        // 创建事件Tap
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventsToWatch,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ 无法创建事件监听")
            return
        }
        
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    private func handleEvent(type: CGEventType, event: CGEvent) {
        let mouseButton = CGEventField(mouseEventButtonNumber)
        let buttonNumber = event.getIntegerValueField(mouseButton)
        let location = event.location
        
        switch type {
        case .otherMouseDown, .mouseDown:
            if buttonNumber == triggerButton.rawValue {
                startDrawing(at: location)
            }
            
        case .otherMouseDragged, .mouseDragged:
            if isDrawing {
                addPoint(location)
            }
            
        case .otherMouseUp, .mouseUp:
            if isDrawing && buttonNumber == triggerButton.rawValue {
                finishDrawing()
            }
            
        default:
            break
        }
    }
    
    private func startDrawing(at point: CGPoint) {
        isDrawing = true
        pathPoints = [point]
        
        // 显示绘制窗口
        overlayWindow?.orderFrontRegardless
        overlayView?.clear()
        
        // 播放开始音效
        NSSound(named: .init("Pop"))?.play()
    }
    
    private func addPoint(_ point: CGPoint) {
        pathPoints.append(point)
        overlayView?.addPoint(point)
        delegate?.gestureTracker(self, didDrawPath: pathPoints)
    }
    
    private func finishDrawing() {
        isDrawing = false
        
        // 延迟隐藏窗口（让用户看到轨迹）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.overlayWindow?.orderOut(nil)
        }
        
        // 识别手势
        guard pathPoints.count > 5 else {
            // 点太少，不识别
            return
        }
        
        let result = recognizer.recognize(path: pathPoints)
        
        if let (name, confidence) = result {
            print("✅ 识别到手势: \(name), 置信度: \(String(format: "%.1f", confidence * 100))%")
            delegate?.gestureTracker(self, didRecognizeGesture: name, confidence: confidence)
            executeAction(forGesture: name)
        } else {
            print("❌ 未识别到匹配的手势")
        }
        
        pathPoints = []
        overlayView?.clear()
    }
    
    private func executeAction(forGesture name: String) {
        guard let action = gestureActions[name] else {
            print("⚠️ 手势 '\(name)' 未绑定动作")
            return
        }
        
        switch action {
        case .shortcut(let keyCode, let modifiers):
            executeKeyboardShortcut(keyCode: keyCode, modifiers: modifiers)
            
        case .applescript(let source):
            executeAppleScript(source: source)
            
        case .shell(let command):
            executeShellCommand(command)
            
        case .launchApp(let bundleId):
            launchApplication(bundleIdentifier: bundleId)
            
        case .none:
            break
        }
    }
    
    // MARK: - 动作执行
    
    private func executeKeyboardShortcut(keyCode: Int, modifiers: NSEvent.ModifierFlags) {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // 按下
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: true)
        keyDown?.flags = CGEventFlags(rawValue: modifiers.rawValue)
        keyDown?.post(tap: .cgSessionEventTap)
        
        // 释放
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(keyCode), keyDown: false)
        keyUp?.flags = CGEventFlags(rawValue: modifiers.rawValue)
        keyUp?.post(tap: .cgSessionEventTap)
    }
    
    private func executeAppleScript(source: String) {
        var errorInfo: NSDictionary?
        if let script = NSAppleScript(source: source) {
            script.executeAndReturnError(&errorInfo)
            if let error = errorInfo {
                print("❌ AppleScript 执行失败: \(error)")
            }
        }
    }
    
    private func executeShellCommand(_ command: String) {
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", command]
            
            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                print("❌ Shell 命令执行失败: \(error)")
            }
        }
    }
    
    private func launchApplication(bundleIdentifier: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            print("❌ 未找到应用: \(bundleIdentifier)")
            return
        }
        
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
    
    // MARK: - 加载模板
    
    private func loadGestureTemplates() {
        // 添加默认手势模板
        recognizer.addTemplates([
            // 圆形
            GestureTemplate(name: "circle", points: generateCirclePoints()),
            // 向右箭头
            GestureTemplate(name: "right", points: generateArrowRightPoints()),
            // 向左箭头
            GestureTemplate(name: "left", points: generateArrowLeftPoints()),
            // 向上箭头
            GestureTemplate(name: "up", points: generateArrowUpPoints()),
            // 向下箭头
            GestureTemplate(name: "down", points: generateArrowDownPoints()),
            // S 形
            GestureTemplate(name: "s", points: generateSPoints()),
            // C 形
            GestureTemplate(name: "c", points: generateCPoints()),
            // M 形
            GestureTemplate(name: "m", points: generateMPoints()),
        ])
    }
    
    // MARK: - 预设手势点生成
    
    private func generateCirclePoints() -> [CGPoint] {
        var points: [CGPoint] = []
        for i in 0..<32 {
            let angle = CGFloat(i) * 2 * .pi / 32
            points.append(CGPoint(x: cos(angle), y: sin(angle)))
        }
        return points
    }
    
    private func generateArrowRightPoints() -> [CGPoint] {
        return [
            CGPoint(x: -1, y: 0),
            CGPoint(x: 1, y: 0)
        ]
    }
    
    private func generateArrowLeftPoints() -> [CGPoint] {
        return [
            CGPoint(x: 1, y: 0),
            CGPoint(x: -1, y: 0)
        ]
    }
    
    private func generateArrowUpPoints() -> [CGPoint] {
        return [
            CGPoint(x: 0, y: 1),
            CGPoint(x: 0, y: -1)
        ]
    }
    
    private func generateArrowDownPoints() -> [CGPoint] {
        return [
            CGPoint(x: 0, y: -1),
            CGPoint(x: 0, y: 1)
        ]
    }
    
    private func generateSPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        for i in 0...20 {
            let t = CGFloat(i) / 20
            let x = sin(t * 2 * .pi)
            let y = t * 2 - 1
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
    
    private func generateCPoints() -> [CGPoint] {
        var points: [CGPoint] = []
        for i in 0...20 {
            let angle = CGFloat(i) * .pi / 20 - .pi / 2
            points.append(CGPoint(x: cos(angle), y: sin(angle)))
        }
        return points
    }
    
    private func generateMPoints() -> [CGPoint] {
        return [
            CGPoint(x: -1, y: -1),
            CGPoint(x: -1, y: 1),
            CGPoint(x: 0, y: 0),
            CGPoint(x: 1, y: 1),
            CGPoint(x: 1, y: -1)
        ]
    }
}

// MARK: - CGEvent 扩展

extension CGEvent {
    var location: CGPoint {
        return CGPoint(x: getDoubleValueField(.mouseEventX), y: getDoubleValueField(.mouseEventY))
    }
    
    private static let mouseEventButtonNumber = CGEventField(rawValue: 886)!
}

extension NSEvent.EventButton {
    var rawValue: Int32 {
        switch self {
        case .left: return 0
        case .right: return 1
        case .other: return 2
        default: return -1
        }
    }
}
