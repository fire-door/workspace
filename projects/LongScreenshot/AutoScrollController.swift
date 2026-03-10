//
//  AutoScrollController.swift
//  自动滚动控制
//
//  功能：
//  1. 检测可滚动区域
//  2. 自动控制滚动
//  3. 平滑滚动动画
//

import Cocoa

// MARK: - 滚动方向

enum ScrollDirection {
    case up
    case down
    case left
    case right
}

// MARK: - 滚动模式

enum ScrollMode {
    case manual      // 手动滚动（用户控制）
    case auto        // 自动滚动（软件控制）
    case adaptive    // 自适应（根据内容调整）
}

// MARK: - 滚动配置

struct ScrollConfig {
    var speed: CGFloat = 50              // 滚动速度（像素/次）
    var interval: TimeInterval = 0.05    // 滚动间隔（秒）
    var acceleration: CGFloat = 1.1      // 加速系数
    var deceleration: CGFloat = 0.9      // 减速系数
    var maxSpeed: CGFloat = 200          // 最大速度
    var minSpeed: CGFloat = 10           // 最小速度
}

// MARK: - 自动滚动控制器

class AutoScrollController {
    
    // 配置
    var config = ScrollConfig()
    
    // 状态
    private(set) var isScrolling = false
    private(set) var direction: ScrollDirection = .down
    private(set) var mode: ScrollMode = .manual
    
    // 当前速度
    private var currentSpeed: CGFloat = 0
    
    // 目标窗口
    private var targetWindow: AXUIElement?
    
    // 定时器
    private var scrollTimer: Timer?
    
    // 回调
    var onScroll: ((CGFloat) -> Void)?           // 滚动回调（偏移量）
    var onReachBoundary: (() -> Void)?           // 到达边界
    var onSpeedChange: ((CGFloat) -> Void)?      // 速度变化
    
    // MARK: - 初始化
    
    init() {
        setupAccessibility()
    }
    
    // MARK: - 公开方法
    
    /// 开始自动滚动
    func startAutoScroll(
        in window: AXUIElement? = nil,
        direction: ScrollDirection = .down,
        mode: ScrollMode = .auto
    ) {
        guard !isScrolling else { return }
        
        self.direction = direction
        self.mode = mode
        self.targetWindow = window ?? getFrontmostWindow()
        self.currentSpeed = config.speed
        self.isScrolling = true
        
        startScrollTimer()
    }
    
    /// 停止滚动
    func stopScroll() {
        guard isScrolling else { return }
        
        stopScrollTimer()
        isScrolling = false
        currentSpeed = 0
    }
    
    /// 暂停滚动
    func pauseScroll() {
        scrollTimer?.fireDate = .distantFuture
    }
    
    /// 恢复滚动
    func resumeScroll() {
        scrollTimer?.fireDate = .now
    }
    
    /// 加速
    func accelerate() {
        currentSpeed = min(currentSpeed * config.acceleration, config.maxSpeed)
        onSpeedChange?(currentSpeed)
    }
    
    /// 减速
    func decelerate() {
        currentSpeed = max(currentSpeed * config.deceleration, config.minSpeed)
        onSpeedChange?(currentSpeed)
    }
    
    /// 设置速度
    func setSpeed(_ speed: CGFloat) {
        currentSpeed = min(max(speed, config.minSpeed), config.maxSpeed)
        onSpeedChange?(currentSpeed)
    }
    
    /// 单次滚动（手动模式）
    func scrollOnce(direction: ScrollDirection, distance: CGFloat) {
        performScroll(direction: direction, distance: distance)
    }
    
    // MARK: - 私有方法
    
    private func setupAccessibility() {
        // 检查辅助功能权限
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            print("⚠️ 需要辅助功能权限才能自动滚动")
        }
    }
    
    private func startScrollTimer() {
        scrollTimer = Timer.scheduledTimer(
            withTimeInterval: config.interval,
            repeats: true
        ) { [weak self] _ in
            self?.performAutoScroll()
        }
        
        RunLoop.current.add(scrollTimer!, forMode: .common)
    }
    
    private func stopScrollTimer() {
        scrollTimer?.invalidate()
        scrollTimer = nil
    }
    
    private func performAutoScroll() {
        // 检测是否到达边界
        if isAtBoundary() {
            onReachBoundary?()
            stopScroll()
            return
        }
        
        // 执行滚动
        performScroll(direction: direction, distance: currentSpeed)
        
        // 自适应模式：根据内容调整速度
        if mode == .adaptive {
            adjustSpeedAdaptively()
        }
    }
    
    private func performScroll(direction: ScrollDirection, distance: CGFloat) {
        // 创建滚动事件
        let scrollValue: Int32
        
        switch direction {
        case .down:
            scrollValue = Int32(-distance)
        case .up:
            scrollValue = Int32(distance)
        case .right:
            scrollValue = Int32(-distance)
        case .left:
            scrollValue = Int32(distance)
        }
        
        // 创建 CGEvent
        let event = CGEvent(
            scrollWheelEvent: nil,
            units: .pixel,
            value1: direction == .up || direction == .down ? scrollValue : 0,
            value2: direction == .left || direction == .right ? scrollValue : 0,
            value3: 0
        )
        
        // 发送事件
        event?.post(tap: .cgSessionEventTap)
        
        // 回调
        onScroll?(distance)
    }
    
    private func isAtBoundary() -> Bool {
        guard let window = targetWindow else { return false }
        
        // 使用 Accessibility API 检测边界
        var scrollBar: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            window,
            kAXVerticalScrollBarAttribute as CFString,
            &scrollBar
        )
        
        if result == .success, let bar = scrollBar {
            // 获取滚动条位置
            var value: CFTypeRef?
            var maxValue: CFTypeRef?
            
            AXUIElementCopyAttributeValue(bar as! AXUIElement, kAXValueAttribute as CFString, &value)
            AXUIElementCopyAttributeValue(bar as! AXUIElement, kAXMaxValueAttribute as CFString, &maxValue)
            
            if let currentValue = value as? CGFloat,
               let max = maxValue as? CGFloat {
                
                if direction == .down && currentValue >= max - 1 {
                    return true
                }
                
                if direction == .up && currentValue <= 1 {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func adjustSpeedAdaptively() {
        // 根据内容密度调整速度
        // 这里可以结合截图捕获的结果来动态调整
        
        // 简化实现：保持匀速
        // 实际可以根据：
        // 1. 内容变化频率
        // 2. 图像匹配成功率
        // 3. 滚动流畅度
        // 来动态调整
    }
    
    private func getFrontmostWindow() -> AXUIElement? {
        let app = NSWorkspace.shared.frontmostApplication
        let pid = app?.processIdentifier ?? 0
        
        let appRef = AXUIElementCreateApplication(pid)
        
        var window: CFTypeRef?
        AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &window)
        
        return window as! AXUIElement?
    }
}

// MARK: - 可滚动区域检测

extension AutoScrollController {
    
    /// 检测窗口中的可滚动区域
    func detectScrollableAreas(in window: AXUIElement) -> [CGRect] {
        var areas: [CGRect] = []
        
        // 获取所有子元素
        var children: CFTypeRef?
        AXUIElementCopyAttributeValue(window, kAXChildrenAttribute as CFString, &children)
        
        guard let elements = children as? [AXUIElement] else {
            return areas
        }
        
        // 递归查找滚动视图
        for element in elements {
            if let scrollArea = findScrollView(in: element) {
                if let frame = getFrame(for: scrollArea) {
                    areas.append(frame)
                }
            }
        }
        
        return areas
    }
    
    private func findScrollView(in element: AXUIElement) -> AXUIElement? {
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
        
        if let roleString = role as? String,
           roleString == kAXScrollAreaRole as String {
            return element
        }
        
        // 递归查找
        var children: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)
        
        if let childElements = children as? [AXUIElement] {
            for child in childElements {
                if let found = findScrollView(in: child) {
                    return found
                }
            }
        }
        
        return nil
    }
    
    private func getFrame(for element: AXUIElement) -> CGRect? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXFrameAttribute as CFString,
            &value
        )
        
        guard result == .success,
              let frameValue = value else {
            return nil
        }
        
        var frame = CGRect.zero
        AXValueGetValue(frameValue as! AXValue, .cgRect, &frame)
        
        return frame
    }
}
