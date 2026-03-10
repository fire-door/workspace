//
//  LongScreenshotCapture.swift
//  长截图捕获与拼接实现
//
//  核心功能：
//  1. 检测滚动事件
//  2. 固定频率截取屏幕
//  3. 图像拼接算法
//  4. 实时预览
//

import Cocoa
import CoreImage

// MARK: - 长截图状态

enum LongScreenshotState {
    case idle           // 空闲
    case selecting      // 选择区域中
    case capturing      // 捕获中
    case processing     // 处理中
    case finished       // 完成
}

// MARK: - 截图帧

struct ScreenshotFrame {
    let image: NSImage
    let timestamp: TimeInterval
    let scrollOffset: CGFloat
    var overlapRegion: CGRect?
}

// MARK: - 拼接配置

struct StitchConfig {
    var minOverlap: CGFloat = 50          // 最小重叠区域
    var maxOverlap: CGFloat = 200         // 最大重叠区域
    var matchThreshold: Double = 0.85     // 匹配阈值
    var captureInterval: TimeInterval = 0.05  // 截图间隔（秒）
    var scrollSpeedThreshold: CGFloat = 100   // 滚动速度阈值
}

// MARK: - 长截图管理器

class LongScreenshotCapture: NSObject {
    
    // 单例
    static let shared = LongScreenshotCapture()
    
    // 状态
    private(set) var state: LongScreenshotState = .idle
    
    // 配置
    var config = StitchConfig()
    
    // 捕获区域
    private var captureRect: CGRect = .zero
    
    // 截图帧缓存
    private var frames: [ScreenshotFrame] = []
    
    // 最终结果
    private(set) var resultImage: NSImage?
    
    // 滚动检测
    private var lastScrollTime: TimeInterval = 0
    private var lastScrollOffset: CGFloat = 0
    private var isScrolling = false
    
    // 定时器
    private var captureTimer: Timer?
    
    // 回调
    var onStateChanged: ((LongScreenshotState) -> Void)?
    var onFrameCaptured: ((NSImage, Int) -> Void)?
    var onProgress: ((Double) -> Void)?
    var onFinished: ((NSImage?) -> Void)?
    
    // MARK: - 公开方法
    
    /// 开始长截图
    func startCapture(in rect: CGRect) {
        guard state == .idle else { return }
        
        captureRect = rect
        frames = []
        resultImage = nil
        
        setState(.selecting)
        
        // 开始监听滚动
        startScrollMonitoring()
    }
    
    /// 开始捕获（用户确认区域后）
    func beginCapturing() {
        guard state == .selecting else { return }
        
        setState(.capturing)
        
        // 开始定时截图
        startCaptureTimer()
        
        // 截取第一帧
        captureFrame()
    }
    
    /// 停止捕获并处理
    func stopCapture() {
        guard state == .capturing else { return }
        
        stopCaptureTimer()
        stopScrollMonitoring()
        
        setState(.processing)
        
        // 异步处理拼接
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.stitchFrames()
        }
    }
    
    /// 取消
    func cancel() {
        stopCaptureTimer()
        stopScrollMonitoring()
        
        frames = []
        resultImage = nil
        
        setState(.idle)
    }
    
    // MARK: - 私有方法 - 状态管理
    
    private func setState(_ newState: LongScreenshotState) {
        state = newState
        DispatchQueue.main.async {
            self.onStateChanged?(newState)
        }
    }
    
    // MARK: - 私有方法 - 滚动监听
    
    private func startScrollMonitoring() {
        // 监听全局滚动事件
        NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
        }
        
        // 监听本地滚动事件（应用内）
        NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event)
            return event
        }
    }
    
    private func stopScrollMonitoring() {
        // NSEvent 的 monitor 会在对象释放时自动移除
    }
    
    private func handleScrollEvent(_ event: NSEvent) {
        let currentTime = Date().timeIntervalSince1970
        let deltaY = event.scrollingDeltaY
        
        // 检测滚动
        if abs(deltaY) > 2 {
            isScrolling = true
            lastScrollTime = currentTime
            lastScrollOffset += deltaY
        }
    }
    
    // MARK: - 私有方法 - 截图捕获
    
    private func startCaptureTimer() {
        captureTimer = Timer.scheduledTimer(
            withTimeInterval: config.captureInterval,
            repeats: true
        ) { [weak self] _ in
            self?.captureFrame()
        }
        
        RunLoop.current.add(captureTimer!, forMode: .common)
    }
    
    private func stopCaptureTimer() {
        captureTimer?.invalidate()
        captureTimer = nil
    }
    
    private func captureFrame() {
        guard state == .capturing else { return }
        
        // 截取屏幕
        guard let image = captureScreen(rect: captureRect) else {
            return
        }
        
        let frame = ScreenshotFrame(
            image: image,
            timestamp: Date().timeIntervalSince1970,
            scrollOffset: lastScrollOffset,
            overlapRegion: nil
        )
        
        frames.append(frame)
        
        DispatchQueue.main.async {
            self.onFrameCaptured?(image, self.frames.count)
        }
    }
    
    private func captureScreen(rect: CGRect) -> NSImage? {
        guard let windowIDs = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        // 创建截图
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
    
    // MARK: - 私有方法 - 图像拼接
    
    private func stitchFrames() {
        guard frames.count > 0 else {
            finishWithResult(nil)
            return
        }
        
        if frames.count == 1 {
            finishWithResult(frames[0].image)
            return
        }
        
        var stitchedImages: [NSImage] = [frames[0].image]
        
        for i in 1..<frames.count {
            let currentImage = frames[i].image
            let previousImage = stitchedImages.last!
            
            // 计算重叠区域
            if let (overlap, offset) = findOverlap(
                top: previousImage,
                bottom: currentImage
            ) {
                // 拼接图像
                if let merged = mergeImages(
                    top: previousImage,
                    bottom: currentImage,
                    overlap: overlap,
                    offset: offset
                ) {
                    stitchedImages.removeLast()
                    stitchedImages.append(merged)
                } else {
                    stitchedImages.append(currentImage)
                }
            } else {
                // 无法找到重叠区域，直接添加
                stitchedImages.append(currentImage)
            }
            
            // 更新进度
            let progress = Double(i) / Double(frames.count)
            DispatchQueue.main.async {
                self.onProgress?(progress)
            }
        }
        
        // 最终结果
        finishWithResult(stitchedImages.last)
    }
    
    // MARK: - 图像匹配算法
    
    /// 查找两张图的重叠区域
    private func findOverlap(top: NSImage, bottom: NSImage) -> (CGFloat, CGFloat)? {
        // 转换为 CIImage
        guard let topCG = top.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let bottomCG = bottom.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let topCI = CIImage(cgImage: topCG)
        let bottomCI = CIImage(cgImage: bottomCG)
        
        // 在底部图像的顶部搜索与顶部图像底部的匹配区域
        let searchRange = config.minOverlap...config.maxOverlap
        
        var bestMatch: (CGFloat, Double)? = nil
        
        // 遍历可能的重叠高度
        for overlapHeight in stride(from: config.maxOverlap, through: config.minOverlap, by: -10) {
            let similarity = calculateSimilarity(
                topImage: topCI,
                bottomImage: bottomCI,
                overlapHeight: overlapHeight
            )
            
            if similarity >= config.matchThreshold {
                bestMatch = (overlapHeight, similarity)
                break  // 找到最佳匹配
            }
        }
        
        if let match = bestMatch {
            return (match.0, match.1)
        }
        
        return nil
    }
    
    /// 计算两张图的相似度
    private func calculateSimilarity(
        topImage: CIImage,
        bottomImage: CIImage,
        overlapHeight: CGFloat
    ) -> Double {
        // 提取顶部图像的底部区域
        let topBottomRegion = topImage
            .cropped(to: CGRect(
                x: 0,
                y: 0,
                width: topImage.extent.width,
                height: overlapHeight
            ))
        
        // 提取底部图像的顶部区域
        let bottomTopRegion = bottomImage
            .cropped(to: CGRect(
                x: 0,
                y: bottomImage.extent.height - overlapHeight,
                width: bottomImage.extent.width,
                height: overlapHeight
            ))
        
        // 使用像素比对计算相似度
        return pixelCompare(topBottomRegion, bottomTopRegion)
    }
    
    /// 像素级比对
    private func pixelCompare(_ image1: CIImage, _ image2: CIImage) -> Double {
        guard let cgImage1 = CIContext().createCGImage(image1, from: image1.extent),
              let cgImage2 = CIContext().createCGImage(image2, from: image2.extent) else {
            return 0
        }
        
        // 简化：采样比对
        let sampleSize = 100
        var matchCount = 0
        var totalCount = 0
        
        for _ in 0..<sampleSize {
            let x = CGFloat.random(in: 0..<image1.extent.width)
            let y = CGFloat.random(in: 0..<image1.extent.height)
            
            if let color1 = getPixelColor(cgImage: cgImage1, at: CGPoint(x: x, y: y)),
               let color2 = getPixelColor(cgImage: cgImage2, at: CGPoint(x: x, y: y)) {
                if colorsMatch(color1, color2, tolerance: 10) {
                    matchCount += 1
                }
                totalCount += 1
            }
        }
        
        return totalCount > 0 ? Double(matchCount) / Double(totalCount) : 0
    }
    
    private func getPixelColor(cgImage: CGImage, at point: CGPoint) -> NSColor? {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data else {
            return nil
        }
        
        let pointer = CFDataGetBytePtr(data)
        let bytesPerRow = cgImage.bytesPerRow
        
        let x = Int(point.x)
        let y = Int(point.y)
        
        let offset = bytesPerRow * y + x * 4
        
        guard offset + 3 < CFDataGetLength(data) else {
            return nil
        }
        
        let r = CGFloat(pointer![offset]) / 255.0
        let g = CGFloat(pointer![offset + 1]) / 255.0
        let b = CGFloat(pointer![offset + 2]) / 255.0
        let a = CGFloat(pointer![offset + 3]) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
    
    private func colorsMatch(_ c1: NSColor, _ c2: NSColor, tolerance: CGFloat) -> Bool {
        let dr = abs(c1.redComponent - c2.redComponent) * 255
        let dg = abs(c1.greenComponent - c2.greenComponent) * 255
        let db = abs(c1.blueComponent - c2.blueComponent) * 255
        
        return dr <= tolerance && dg <= tolerance && db <= tolerance
    }
    
    // MARK: - 图像合并
    
    private func mergeImages(
        top: NSImage,
        bottom: NSImage,
        overlap: CGFloat,
        offset: CGFloat
    ) -> NSImage? {
        let topSize = top.size
        let bottomSize = bottom.size
        
        // 计算合并后的尺寸
        let mergedWidth = max(topSize.width, bottomSize.width)
        let mergedHeight = topSize.height + bottomSize.height - overlap
        
        // 创建新图像
        let mergedImage = NSImage(size: NSSize(width: mergedWidth, height: mergedHeight))
        
        mergedImage.lockFocus()
        
        // 绘制顶部图像
        top.draw(
            in: NSRect(x: 0, y: mergedHeight - topSize.height, width: topSize.width, height: topSize.height)
        )
        
        // 绘制底部图像（去除重叠部分）
        let bottomDrawRect = NSRect(
            x: 0,
            y: 0,
            width: bottomSize.width,
            height: bottomSize.height - overlap
        )
        
        if let cgImage = bottom.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let cropRect = CGRect(
                x: 0,
                y: 0,
                width: bottomSize.width,
                height: bottomSize.height - overlap
            )
            
            if let cropped = cgImage.cropping(to: cropRect) {
                let croppedImage = NSImage(cgImage: cropped, size: cropRect.size)
                croppedImage.draw(in: bottomDrawRect)
            }
        }
        
        mergedImage.unlockFocus()
        
        return mergedImage
    }
    
    // MARK: - 完成
    
    private func finishWithResult(_ image: NSImage?) {
        resultImage = image
        
        DispatchQueue.main.async {
            self.setState(.finished)
            self.onFinished?(image)
            
            // 重置状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.setState(.idle)
            }
        }
    }
}
