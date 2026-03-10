//
//  GestureTracker+Bindings.swift
//  手势动作绑定扩展
//

import Foundation
import Cocoa

// MARK: - 动作绑定扩展

extension GestureTracker {
    
    /// 绑定快捷键动作到手势
    func bindShortcut(_ keyCode: CGKeyCode, modifiers: NSEvent.ModifierFlags = [], toGesture name: String) {
        bindAction(.shortcut(keyCode: Int(keyCode), modifiers: modifiers), toGesture: name)
    }
    
    /// 绑定 AppleScript 动作到手势
    func bindAppleScript(_ source: String, toGesture name: String) {
        bindAction(.applescript(source: source), toGesture: name)
    }
    
    /// 绑定 Shell 命令动作到手势
    func bindShellCommand(_ command: String, toGesture name: String) {
        bindAction(.shell(command: command), toGesture: name)
    }
    
    /// 绑定启动应用动作到手势
    func bindLaunchApp(bundleIdentifier: String, toGesture name: String) {
        bindAction(.launchApp(bundleIdentifier: bundleIdentifier), toGesture: name)
    }
    
    /// 绑定预设动作到手势
    func bindAction(_ action: GestureAction, toGesture name: String) {
        gestureActions[name] = action
    }
    
    /// 移除手势绑定
    func removeBinding(forGesture name: String) {
        gestureActions.removeValue(forKey: name)
    }
    
    /// 清除所有绑定
    func clearAllBindings() {
        gestureActions.removeAll()
    }
}

// MARK: - 常用快捷键扩展

extension GestureAction {
    
    /// 创建快捷键动作
    static func shortcut(keyCode: Int, modifiers: NSEvent.ModifierFlags = []) -> GestureAction {
        return .shortcut(keyCode: keyCode, modifiers: modifiers)
    }
    
    /// Command + Q (退出应用)
    static let quitApp = GestureAction.shortcut(keyCode: 12, modifiers: .command)
    
    /// Command + W (关闭窗口)
    static let closeWindow = GestureAction.shortcut(keyCode: 13, modifiers: .command)
    
    /// Command + Tab (切换应用)
    static let switchApp = GestureAction.shortcut(keyCode: 48, modifiers: .command)
    
    /// Control + 左箭头 (上一桌面)
    static let prevDesktop = GestureAction.shortcut(keyCode: 123, modifiers: .control)
    
    /// Control + 右箭头 (下一桌面)
    static let nextDesktop = GestureAction.shortcut(keyCode: 124, modifiers: .control)
    
    /// Control + 上箭头 (Mission Control)
    static let missionControl = GestureAction.shortcut(keyCode: 126, modifiers: .control)
    
    /// F11 (显示桌面)
    static let showDesktop = GestureAction.shortcut(keyCode: 103, modifiers: .function)
    
    /// Command + Space (Spotlight)
    static let spotlight = GestureAction.shortcut(keyCode: 49, modifiers: .command)
    
    /// Command + Shift + 3 (全屏截图)
    static let screenshotFullscreen = GestureAction.shortcut(keyCode: 20, modifiers: [.command, .shift])
    
    /// Command + Shift + 4 (区域截图)
    static let screenshotRegion = GestureAction.shortcut(keyCode: 21, modifiers: [.command, .shift])
}

// MARK: - 常用应用 Bundle ID

extension GestureAction {
    
    struct Apps {
        static let safari = "com.apple.Safari"
        static let mail = "com.apple.Mail"
        static let finder = "com.apple.finder"
        static let notes = "com.apple.Notes"
        static let calendar = "com.apple.iCal"
        static let reminders = "com.apple.reminders"
        static let messages = "com.apple.iChat"
        static let music = "com.apple.Music"
        static let terminal = "com.apple.Terminal"
        static let xcode = "com.apple.dt.Xcode"
        static let systemPreferences = "com.apple.systempreferences"
    }
}
