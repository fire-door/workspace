//
//  UsageExamples.swift
//  长截图完整使用示例
//
//  展示如何使用所有组件构建完整的长截图功能
//

import Cocoa

// MARK: - 示例 1: 基础使用

func basicUsageExample() {
    print("=== 基础使用示例 ===")
    
    // 1. 初始化长截图捕获器
    let capture = LongScreenshotCapture.shared
    
    // 2. 配置回调
    capture.onStateChanged = { state in
        print("状态: \(state)")
    }
    
    capture.onFrameCaptured = { image, count in
        print("已捕获第 \(count) 帧")
    }
    
    capture.onProgress = { progress in
        print("进度: \(Int(progress * 100))%")
    }
    
    capture.onFinished = { image in
        if let result = image {
            print("✓ 长截图完成: \(result.size)")
            
            // 保存结果
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop/long_screenshot.png")
            try? result.save(to: url)
        }
    }
    
    // 3. 选择截图区域
    let rect = CGRect(x: 0, y: 0, width: 1200, height: 800)
    capture.startCapture(in: rect)
    
    // 4. 开始捕获
    capture.beginCapturing()
    
    // 5. 用户滚动后停止（模拟）
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        capture.stopCapture()
    }
}

// MARK: - 示例 2: 带预览的完整流程

func fullFlowWithPreviewExample() {
    print("=== 带预览的完整流程 ===")
    
    // 1. 显示预览窗口
    let preview = LongScreenshotPreview.showOnScreen()
    
    // 2. 开始选择区域
    preview.startSelection()
    
    // 3. 监听选择完成
    NotificationCenter.default.addObserver(
        forName: .selectionCompleted,
        object: nil,
        queue: .main
    ) { notification in
        guard let rect = notification.userInfo?["rect"] as? CGRect else { return }
        
        print("选择的区域: \(rect)")
        
        // 4. 开始捕获
        let capture = LongScreenshotCapture.shared
        capture.startCapture(in: rect)
        capture.beginCapturing()
        
        // 5. 更新预览
        capture.onFrameCaptured = { image, count in
            preview.updateProgress(frameCount: count, currentHeight: 0, preview: image)
        }
        
        capture.onFinished = { image in
            if let result = image {
                preview.showCompletion(image: result)
            }
        }
    }
}

// MARK: - 示例 3: 自动滚动模式

func autoScrollExample() {
    print("=== 自动滚动示例 ===")
    
    // 1. 初始化自动滚动控制器
    let scrollController = AutoScrollController()
    
    // 2. 配置
    var config = ScrollConfig()
    config.speed = 80
    config.interval = 0.05
    scrollController.config = config
    
    // 3. 设置回调
    scrollController.onScroll = { distance in
        print("滚动了: \(distance)px")
    }
    
    scrollController.onReachBoundary = {
        print("到达边界，停止")
        scrollController.stopScroll()
        
        // 停止截图
        LongScreenshotCapture.shared.stopCapture()
    }
    
    // 4. 开始截图
    let capture = LongScreenshotCapture.shared
    capture.startCapture(in: CGRect(x: 0, y: 0, width: 1200, height: 800))
    capture.beginCapturing()
    
    // 5. 开始自动滚动
    scrollController.startScroll(direction: .down, mode: .auto)
}

// MARK: - 示例 4: 自定义配置

func customConfigExample() {
    print("=== 自定义配置示例 ===")
    
    // 1. 获取配置管理器
    let configManager = LongScreenshotConfigManager.shared
    
    // 2. 自定义配置
    var config = LongScreenshotConfig()
    
    // 截图设置
    config.captureInterval = 0.03      // 30 FPS
    config.captureQuality = 0.95       // 高质量
    
    // 拼接设置
    config.minOverlap = 80
    config.maxOverlap = 300
    config.matchThreshold = 0.9
    config.stitchStrategy = .featureMatch  // 使用特征点匹配
    
    // 滚动设置
    config.autoScroll = true
    config.scrollSpeed = 60
    
    // 输出设置
    config.outputFormat = .png
    config.outputQuality = 1.0
    
    // 3. 应用配置
    configManager.update(config)
    
    // 4. 验证配置
    let errors = config.validate()
    if !errors.isEmpty {
        print("配置错误:")
        errors.forEach { print("  - \($0)") }
        return
    }
    
    // 5. 使用配置
    let capture = LongScreenshotCapture.shared
    capture.config.captureInterval = config.captureInterval
}

// MARK: - 示例 5: 图像处理

func imageProcessingExample() {
    print("=== 图像处理示例 ===")
    
    // 假设有一张图像
    guard let image = NSImage(contentsOf: URL(fileURLWithPath: "/tmp/test.png")) else {
        return
    }
    
    // 1. 调整大小
    let resized = image.resized(to: NSSize(width: 800, height: 600))
    print("调整后尺寸: \(resized?.size ?? .zero)")
    
    // 2. 裁剪
    let cropped = image.cropped(to: CGRect(x: 0, y: 0, width: 400, height: 300))
    
    // 3. 转灰度
    let grayscale = image.grayscale()
    
    // 4. 应用模糊
    let blurred = image.blurred(radius: 5)
    
    // 5. 获取像素颜色
    if let color = image.color(at: CGPoint(x: 100, y: 100)) {
        print("像素颜色: \(color)")
    }
    
    // 6. 计算差异
    if let diff = image.difference(from: grayscale!) {
        diff.debugSave(name: "difference")
    }
    
    // 7. 保存
    try? resized?.save(
        to: URL(fileURLWithPath: "/tmp/resized.png"),
        format: .png,
        quality: 1.0
    )
}

// MARK: - 示例 6: 图像拼接

func imageStitchingExample() {
    print("=== 图像拼接示例 ===")
    
    // 准备图像
    let images = [
        NSImage(contentsOf: URL(fileURLWithPath: "/tmp/frame1.png"))!,
        NSImage(contentsOf: URL(fileURLWithPath: "/tmp/frame2.png"))!,
        NSImage(contentsOf: URL(fileURLWithPath: "/tmp/frame3.png"))!
    ]
    
    // 创建拼接器
    let stitcher = ImageStitcher()
    
    // 配置
    stitcher.strategy = .hybrid
    stitcher.minOverlapRatio = 0.1
    stitcher.maxOverlapRatio = 0.4
    stitcher.matchThreshold = 0.85
    
    // 方法 1: 逐张拼接
    var result = images[0]
    for i in 1..<images.count {
        if let merged = stitcher.stitch(top: result, bottom: images[i]) {
            result = merged
            print("拼接第 \(i) 张成功")
        }
    }
    
    // 方法 2: 批量拼接
    if let merged = stitcher.stitchBatch(images, progress: { progress in
        print("拼接进度: \(Int(progress * 100))%")
    }) {
        print("批量拼接完成: \(merged.size)")
    }
    
    // 保存结果
    try? result.save(to: URL(fileURLWithPath: "/tmp/merged.png"))
}

// MARK: - 示例 7: 性能监控

func performanceMonitoringExample() {
    print("=== 性能监控示例 ===")
    
    let monitor = PerformanceMonitor.shared
    
    monitor.start()
    
    // 模拟工作
    Thread.sleep(forTimeInterval: 0.1)
    monitor.checkpoint("初始化完成")
    
    Thread.sleep(forTimeInterval: 0.2)
    monitor.checkpoint("截图完成")
    
    Thread.sleep(forTimeInterval: 0.3)
    monitor.checkpoint("拼接完成")
    
    print(monitor.report())
}

// MARK: - 示例 8: 批量操作

func batchOperationsExample() {
    print("=== 批量操作示例 ===")
    
    // 假设有多张图像
    let images = [NSImage]()
    
    // 批量调整大小
    let resizedImages = images.resized(to: NSSize(width: 800, height: 600))
    
    // 批量保存
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("frames")
    try? images.saveAll(to: directory, format: .png)
    
    // 创建 GIF
    let gifURL = FileManager.default.temporaryDirectory.appendingPathComponent("animation.gif")
    try? images.createGIF(url: gifURL, delay: 0.1, loopCount: 0)
    
    print("✓ 批量操作完成")
}

// MARK: - 示例 9: 完整应用流程

class LongScreenshotApp {
    
    private let capture = LongScreenshotCapture.shared
    private let scrollController = AutoScrollController()
    private var preview: LongScreenshotPreview?
    
    func start() {
        print("=== 启动长截图应用 ===")
        
        // 1. 加载配置
        let config = LongScreenshotConfigManager.shared.config
        print(config.description)
        
        // 2. 显示预览
        preview = LongScreenshotPreview.showOnScreen()
        preview?.startSelection()
        
        // 3. 监听选择完成
        NotificationCenter.default.addObserver(
            forName: .selectionCompleted,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let rect = notification.userInfo?["rect"] as? CGRect else { return }
            self?.startCapture(in: rect)
        }
    }
    
    private func startCapture(in rect: CGRect) {
        // 配置捕获
        capture.config.captureInterval = 0.05
        
        capture.onStateChanged = { [weak self] state in
            self?.handleState(state)
        }
        
        capture.onFrameCaptured = { [weak self] image, count in
            self?.preview?.updateProgress(
                frameCount: count,
                currentHeight: 0,
                preview: image
            )
        }
        
        capture.onFinished = { [weak self] image in
            self?.handleFinished(image)
        }
        
        // 开始捕获
        capture.startCapture(in: rect)
        capture.beginCapturing()
        
        // 如果配置了自动滚动
        if LongScreenshotConfigManager.shared.config.autoScroll {
            scrollController.startScroll(direction: .down, mode: .auto)
        }
    }
    
    private func handleState(_ state: LongScreenshotState) {
        print("状态变化: \(state)")
        
        switch state {
        case .finished:
            scrollController.stopScroll()
        default:
            break
        }
    }
    
    private func handleFinished(_ image: NSImage?) {
        guard let result = image else {
            preview?.showError("截图失败")
            return
        }
        
        preview?.showCompletion(image: result)
        
        // 保存结果
        let config = LongScreenshotConfigManager.shared.config
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/long_screenshot_\(Date().timeIntervalSince1970).\(config.outputFormat.fileExtension)")
        
        do {
            try result.save(to: url, format: config.outputFormat, quality: config.outputQuality)
            print("✓ 已保存到: \(url.path)")
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }
    
    func stop() {
        capture.stopCapture()
        scrollController.stopScroll()
        preview?.hide()
    }
}

// MARK: - 使用方式

/*
 
 // 简单使用
 basicUsageExample()
 
 // 带预览的完整流程
 fullFlowWithPreviewExample()
 
 // 自动滚动
 autoScrollExample()
 
 // 自定义配置
 customConfigExample()
 
 // 图像处理
 imageProcessingExample()
 
 // 图像拼接
 imageStitchingExample()
 
 // 完整应用
 let app = LongScreenshotApp()
 app.start()
 
 */
