//
//  LongScreenshotPreview.swift
//  长截图实时预览视图
//
//  功能：
//  1. 实时显示捕获进度
//  2. 预览拼接结果
//  3. 显示区域选择框
//

import Cocoa

// MARK: - 预览视图配置

struct PreviewConfig {
    var showBorder: Bool = true
    var borderColor: NSColor = .systemBlue
    var borderWidth: CGFloat = 2
    var showProgress: Bool = true
    var showSize: Bool = true
    var thumbnailSize: CGFloat = 200
}

// MARK: - 长截图预览视图

class LongScreenshotPreview: NSView {
    
    // 配置
    var config = PreviewConfig()
    
    // 状态
    private(set) var isSelecting = false
    private(set) var selectionRect: CGRect = .zero
    
    // 捕获的图像
    private var capturedFrames: [NSImage] = []
    private var previewImage: NSImage?
    
    // 进度
    private(set) var frameCount: Int = 0
    private(set) var currentHeight: CGFloat = 0
    
    // UI 元素
    private var statusLabel: NSTextField?
    private var thumbnailView: NSImageView?
    private var progressIndicator: NSProgressIndicator?
    
    // 拖动选择
    private var dragStartPoint: CGPoint = .zero
    private var isDragging = false
    
    // MARK: - 初始化
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        
        // 状态标签
        statusLabel = NSTextField(labelWithString: "等待开始...")
        statusLabel?.textColor = .white
        statusLabel?.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel?.alignment = .center
        addSubview(statusLabel!)
        
        // 缩略图
        thumbnailView = NSImageView(frame: .zero)
        thumbnailView?.wantsLayer = true
        thumbnailView?.layer?.borderColor = NSColor.white.cgColor
        thumbnailView?.layer?.borderWidth = 2
        thumbnailView?.layer?.cornerRadius = 8
        thumbnailView?.imageScaling = .scaleProportionallyUpOrDown
        addSubview(thumbnailView!)
        
        // 进度条
        progressIndicator = NSProgressIndicator(frame: .zero)
        progressIndicator?.minValue = 0
        progressIndicator?.maxValue = 100
        progressIndicator?.isIndeterminate = false
        progressIndicator?.style = .bar
        addSubview(progressIndicator!)
        
        // 布局
        layoutUI()
    }
    
    private func layoutUI() {
        let padding: CGFloat = 20
        let thumbnailSize = config.thumbnailSize
        
        // 状态标签
        statusLabel?.frame = NSRect(
            x: padding,
            y: bounds.height - 40,
            width: bounds.width - padding * 2,
            height: 30
        )
        
        // 缩略图（右下角）
        thumbnailView?.frame = NSRect(
            x: bounds.width - thumbnailSize - padding,
            y: padding,
            width: thumbnailSize,
            height: thumbnailSize * 1.5
        )
        
        // 进度条
        progressIndicator?.frame = NSRect(
            x: padding,
            y: padding,
            width: bounds.width - thumbnailSize - padding * 3,
            height: 20
        )
    }
    
    override var frame: NSRect {
        didSet {
            layoutUI()
        }
    }
    
    // MARK: - 公开方法
    
    /// 开始选择区域
    func startSelection() {
        isSelecting = true
        selectionRect = .zero
        statusLabel?.stringValue = "拖动选择截图区域"
        needsDisplay = true
    }
    
    /// 完成选择
    func finishSelection() {
        isSelecting = false
        statusLabel?.stringValue = "按 S 开始，滚动页面，按 Esc 停止"
        needsDisplay = true
    }
    
    /// 更新捕获进度
    func updateProgress(frameCount: Int, currentHeight: CGFloat, preview: NSImage?) {
        self.frameCount = frameCount
        self.currentHeight = currentHeight
        self.previewImage = preview
        
        // 更新状态
        let sizeText = ByteCountFormatter.string(fromByteCount: Int64(currentHeight), countStyle: .file)
        statusLabel?.stringValue = "已捕获 \(frameCount) 帧 • 高度: \(Int(currentHeight))px"
        
        // 更新缩略图
        if let preview = preview {
            thumbnailView?.image = preview
        }
        
        // 更新进度条（假设最大高度为 10000px）
        let progress = min(currentHeight / 10000.0 * 100, 100)
        progressIndicator?.doubleValue = Double(progress)
        
        needsDisplay = true
    }
    
    /// 显示完成状态
    func showCompletion(image: NSImage) {
        statusLabel?.stringValue = "✓ 长截图完成"
        thumbnailView?.image = image
        
        // 动画效果
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.alphaValue = 0.8
        } completionHandler: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.hide()
            }
        }
    }
    
    /// 显示错误
    func showError(_ message: String) {
        statusLabel?.stringValue = "❌ \(message)"
        statusLabel?.textColor = .systemRed
    }
    
    /// 重置
    func reset() {
        capturedFrames = []
        previewImage = nil
        frameCount = 0
        currentHeight = 0
        selectionRect = .zero
        isSelecting = false
        isDragging = false
        
        statusLabel?.stringValue = "等待开始..."
        statusLabel?.textColor = .white
        thumbnailView?.image = nil
        progressIndicator?.doubleValue = 0
        
        needsDisplay = true
    }
    
    /// 隐藏
    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.alphaValue = 0
        } completionHandler: {
            self.removeFromSuperview()
        }
    }
    
    // MARK: - 鼠标事件
    
    override func mouseDown(with event: NSEvent) {
        guard isSelecting else { return }
        
        isDragging = true
        dragStartPoint = convert(event.locationInWindow, from: nil)
        selectionRect = CGRect(origin: dragStartPoint, size: .zero)
        
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        
        let currentPoint = convert(event.locationInWindow, from: nil)
        
        // 计算选择区域
        let x = min(dragStartPoint.x, currentPoint.x)
        let y = min(dragStartPoint.y, currentPoint.y)
        let width = abs(currentPoint.x - dragStartPoint.x)
        let height = abs(currentPoint.y - dragStartPoint.y)
        
        selectionRect = CGRect(x: x, y: y, width: width, height: height)
        
        // 更新状态
        statusLabel?.stringValue = "\(Int(width)) × \(Int(height))"
        
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        guard isDragging else { return }
        
        isDragging = false
        
        // 通知选择完成
        NotificationCenter.default.post(
            name: .selectionCompleted,
            object: nil,
            userInfo: ["rect": selectionRect]
        )
    }
    
    // MARK: - 绘制
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制选择框
        if isSelecting || !selectionRect.isEmpty {
            drawSelectionRect()
        }
        
        // 绘制预览图像
        if let preview = previewImage {
            drawPreviewImage(preview)
        }
    }
    
    private func drawSelectionRect() {
        guard config.showBorder else { return }
        
        let path = NSBezierPath(rect: selectionRect)
        path.lineWidth = config.borderWidth
        config.borderColor.setStroke()
        path.stroke()
        
        // 填充半透明背景
        config.borderColor.withAlphaComponent(0.1).setFill()
        path.fill()
        
        // 绘制角标
        drawCornerHandles(for: selectionRect)
    }
    
    private func drawCornerHandles(for rect: CGRect) {
        let handleSize: CGFloat = 10
        let handleColor = config.borderColor
        
        // 四个角
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        
        for corner in corners {
            let handleRect = CGRect(
                x: corner.x - handleSize/2,
                y: corner.y - handleSize/2,
                width: handleSize,
                height: handleSize
            )
            
            let handlePath = NSBezierPath(rect: handleRect)
            handleColor.setFill()
            handlePath.fill()
        }
    }
    
    private func drawPreviewImage(_ image: NSImage) {
        // 在左侧绘制缩小的预览
        let maxSize: CGFloat = 150
        let aspectRatio = image.size.width / image.size.height
        
        let previewWidth = min(maxSize, image.size.width)
        let previewHeight = previewWidth / aspectRatio
        
        let previewRect = CGRect(
            x: 20,
            y: bounds.height - previewHeight - 60,
            width: previewWidth,
            height: previewHeight
        )
        
        image.draw(in: previewRect)
    }
}

// MARK: - 通知扩展

extension Notification.Name {
    static let selectionCompleted = Notification.Name("selectionCompleted")
}

// MARK: - 便捷方法

extension LongScreenshotPreview {
    
    /// 在屏幕上显示预览
    static func showOnScreen() -> LongScreenshotPreview {
        guard let screen = NSScreen.main else {
            fatalError("No main screen")
        }
        
        let preview = LongScreenshotPreview(frame: screen.frame)
        
        // 创建全屏窗口
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.contentView = preview
        window.makeKeyAndOrderFront(nil)
        
        return preview
    }
}
