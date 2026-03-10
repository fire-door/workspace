//
//  AppDelegate.swift
//  GestureTracker 应用入口
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, GestureTrackerDelegate {
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var trackingEnabled = false
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        requestAccessibilityPermission()
    }
    
    // MARK: - 菜单栏设置
    
    private func setupMenuBar() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "hand.draw", accessibilityDescription: "GestureTracker")
            button.toolTip = "GestureTracker - 按住右键绘制手势"
        }
        
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "开始追踪", action: #selector(toggleTracking), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        // 更新菜单项状态
        updateMenuState()
    }
    
    private func updateMenuState() {
        guard let menu = statusItem.menu else { return }
        menu.items[0].title = trackingEnabled ? "停止追踪" : "开始追踪"
    }
    
    // MARK: - 辅助功能权限
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = "GestureTracker 需要辅助功能权限才能监听全局鼠标事件。\n\n请在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能 中授权。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "打开系统偏好设置")
            alert.addButton(withTitle: "稍后")
            
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
    
    // MARK: - 动作
    
    @objc private func toggleTracking() {
        let tracker = GestureTracker.shared
        tracker.delegate = self
        
        if trackingEnabled {
            tracker.stopTracking()
            trackingEnabled = false
            statusItem.button?.image = NSImage(systemSymbolName: "hand.draw", accessibilityDescription: "GestureTracker")
        } else {
            if tracker.startTracking() {
                trackingEnabled = true
                statusItem.button?.image = NSImage(systemSymbolName: "hand.draw.fill", accessibilityDescription: "GestureTracker (激活)")
                setupDefaultGestures()
            }
        }
        
        updateMenuState()
    }
    
    @objc private func openSettings() {
        // TODO: 打开设置窗口
        let alert = NSAlert()
        alert.messageText = "设置"
        alert.informativeText = "设置面板开发中..."
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc private func quit() {
        GestureTracker.shared.stopTracking()
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - 默认手势配置
    
    private func setupDefaultGestures() {
        let tracker = GestureTracker.shared
        
        // 向右箭头 → 切换到下一个桌面
        tracker.bindAction(.shortcut(keyCode: 124, modifiers: [.control]), toGesture: "right")
        
        // 向左箭头 → 切换到上一个桌面
        tracker.bindAction(.shortcut(keyCode: 123, modifiers: [.control]), toGesture: "left")
        
        // 向上箭头 → 打开 Mission Control
        tracker.bindAction(.shortcut(keyCode: 126, modifiers: [.control]), toGesture: "up")
        
        // 向下箭头 → 显示桌面
        tracker.bindAction(.shortcut(keyCode: 125, modifiers: [.function]), toGesture: "down")
        
        // 圆形 → 打开 Spotlight
        tracker.bindAction(.shortcut(keyCode: 49, modifiers: [.command]), toGesture: "circle")
        
        // M 形 → 打开邮件
        tracker.bindAction(.launchApp(bundleIdentifier: "com.apple.Mail"), toGesture: "m")
        
        // S 形 → 打开 Safari
        tracker.bindAction(.launchApp(bundleIdentifier: "com.apple.Safari"), toGesture: "s")
        
        print("✅ 默认手势已配置")
    }
    
    // MARK: - GestureTrackerDelegate
    
    func gestureTracker(_ tracker: GestureTracker, didRecognizeGesture name: String, confidence: Double) {
        DispatchQueue.main.async {
            // 显示识别结果通知
            if let button = self.statusItem.button {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "识别成功")
                } completionHandler: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        button.image = NSImage(systemSymbolName: "hand.draw.fill", accessibilityDescription: "GestureTracker")
                    }
                }
            }
            
            print("🎯 手势识别: \(name) (\(String(format: "%.0f", confidence * 100))%)")
        }
    }
    
    func gestureTracker(_ tracker: GestureTracker, didDrawPath path: [CGPoint]) {
        // 轨迹绘制中（可选处理）
    }
}
