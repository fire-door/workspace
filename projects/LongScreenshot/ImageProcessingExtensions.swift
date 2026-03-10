//
//  ImageProcessingExtensions.swift
//  图像处理工具扩展
//
//  功能：
//  1. 图像处理扩展方法
//  2. 性能优化工具
//  3. 调试辅助工具
//

import Cocoa
import Accelerate
import CoreImage

// MARK: - NSImage 扩展

extension NSImage {
    
    /// 获取 CGImage
    var cgImage: CGImage? {
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    /// 获取像素尺寸
    var pixelSize: NSSize {
        guard let cgImage = cgImage else { return size }
        return NSSize(width: cgImage.width, height: cgImage.height)
    }
    
    /// 调整大小
    func resized(to newSize: NSSize) -> NSImage? {
        let resized = NSImage(size: newSize)
        resized.lockFocus()
        
        draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        
        resized.unlockFocus()
        return resized
    }
    
    /// 按比例缩放
    func scaled(by factor: CGFloat) -> NSImage? {
        let newSize = NSSize(width: size.width * factor, height: size.height * factor)
        return resized(to: newSize)
    }
    
    /// 裁剪
    func cropped(to rect: CGRect) -> NSImage? {
        let cropped = NSImage(size: rect.size)
        cropped.lockFocus()
        
        draw(
            in: NSRect(origin: .zero, size: rect.size),
            from: rect,
            operation: .copy,
            fraction: 1.0
        )
        
        cropped.unlockFocus()
        return cropped
    }
    
    /// 旋转
    func rotated(by angle: CGFloat) -> NSImage? {
        let rotated = NSImage(size: size)
        rotated.lockFocus()
        
        let transform = NSAffineTransform()
        transform.translateX(by: size.width / 2, yBy: size.height / 2)
        transform.rotate(byDegrees: angle * 180 / .pi)
        transform.translateX(by: -size.width / 2, yBy: -size.height / 2)
        transform.concat()
        
        draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        
        rotated.unlockFocus()
        return rotated
    }
    
    /// 翻转
    func flipped(horizontal: Bool = false, vertical: Bool = true) -> NSImage? {
        let flipped = NSImage(size: size)
        flipped.lockFocus()
        
        let transform = NSAffineTransform()
        
        if horizontal {
            transform.translateX(by: size.width, yBy: 0)
            transform.scaleX(by: -1, yBy: 1)
        }
        
        if vertical {
            transform.translateX(by: 0, yBy: size.height)
            transform.scaleX(by: 1, yBy: -1)
        }
        
        transform.concat()
        
        draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        
        flipped.unlockFocus()
        return flipped
    }
    
    /// 转换为灰度
    func grayscale() -> NSImage? {
        guard let cgImage = cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIPhotoEffectMono") else { return nil }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let output = filter.outputImage,
              let outputCG = CIContext().createCGImage(output, from: output.extent) else {
            return nil
        }
        
        return NSImage(cgImage: outputCG, size: size)
    }
    
    /// 应用模糊
    func blurred(radius: CGFloat) -> NSImage? {
        guard let cgImage = cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let output = filter.outputImage,
              let outputCG = CIContext().createCGImage(output, from: ciImage.extent) else {
            return nil
        }
        
        return NSImage(cgImage: outputCG, size: size)
    }
    
    /// 获取像素颜色
    func color(at point: CGPoint) -> NSColor? {
        guard let cgImage = cgImage,
              let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data else {
            return nil
        }
        
        let pointer = CFDataGetBytePtr(data)
        let bytesPerRow = cgImage.bytesPerRow
        
        let x = Int(point.x)
        let y = Int(point.y)
        
        guard x >= 0, x < cgImage.width, y >= 0, y < cgImage.height else {
            return nil
        }
        
        let offset = bytesPerRow * (cgImage.height - y - 1) + x * 4
        
        guard offset + 3 < CFDataGetLength(data) else {
            return nil
        }
        
        let r = CGFloat(pointer![offset]) / 255.0
        let g = CGFloat(pointer![offset + 1]) / 255.0
        let b = CGFloat(pointer![offset + 2]) / 255.0
        let a = CGFloat(pointer![offset + 3]) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// 计算与另一张图的差异
    func difference(from other: NSImage) -> NSImage? {
        // 使用 CIFilter 计算差异
        guard let cgImage1 = cgImage,
              let cgImage2 = other.cgImage else {
            return nil
        }
        
        let ciImage1 = CIImage(cgImage: cgImage1)
        let ciImage2 = CIImage(cgImage: cgImage2)
        
        guard let filter = CIFilter(name: "CIDifferenceBlendMode") else { return nil }
        
        filter.setValue(ciImage1, forKey: kCIInputBackgroundImageKey)
        filter.setValue(ciImage2, forKey: kCIInputImageKey)
        
        guard let output = filter.outputImage,
              let outputCG = CIContext().createCGImage(output, from: output.extent) else {
            return nil
        }
        
        return NSImage(cgImage: outputCG, size: size)
    }
    
    /// 保存到文件
    func save(to url: URL, format: ImageFormat = .png, quality: Double = 0.9) throws {
        guard let cgImage = cgImage else {
            throw ImageError.invalidImage
        }
        
        let destination = CGImageDestinationCreateWithURL(url as CFURL, format.uti as CFString, 1, nil)
        guard let dest = destination else {
            throw ImageError.destinationCreationFailed
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(dest, cgImage, options as CFDictionary)
        CGImageDestinationFinalize(dest)
    }
    
    /// 计算哈希值（用于快速比较）
    func hash() -> UInt64 {
        guard let cgImage = cgImage else { return 0 }
        
        // 简化的哈希计算
        let thumbnail = resized(to: NSSize(width: 8, height: 8))
        guard let thumbnailCG = thumbnail?.cgImage,
              let dataProvider = thumbnailCG.dataProvider,
              let data = dataProvider.data else {
            return 0
        }
        
        let pointer = CFDataGetBytePtr(data)
        var hash: UInt64 = 0
        
        for i in 0..<64 {
            let brightness = pointer![i * 4]  // R channel
            if brightness > 128 {
                hash |= (1 << i)
            }
        }
        
        return hash
    }
}

// MARK: - 图像错误

enum ImageError: Error {
    case invalidImage
    case destinationCreationFailed
    case encodingFailed
}

// MARK: - CGImage 扩展

extension CGImage {
    
    /// 转换为灰度
    var grayscale: CGImage? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }
        
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }
    
    /// 缩放
    func scaled(to newSize: CGSize) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(origin: .zero, size: newSize))
        
        return context.makeImage()
    }
}

// MARK: - 性能监控

class PerformanceMonitor {
    
    static let shared = PerformanceMonitor()
    
    private var startTime: Date?
    private var checkpoints: [(String, Date)] = []
    
    func start() {
        startTime = Date()
        checkpoints = []
    }
    
    func checkpoint(_ name: String) {
        checkpoints.append((name, Date()))
    }
    
    func report() -> String {
        guard let start = startTime else {
            return "未启动监控"
        }
        
        var report = "性能报告:\n"
        report += "总时间: \(Date().timeIntervalSince(start) * 1000)ms\n"
        
        for (index, checkpoint) in checkpoints.enumerated() {
            let elapsed = checkpoint.1.timeIntervalSince(start) * 1000
            report += "  \(index + 1). \(checkpoint.0): \(String(format: "%.2f", elapsed))ms\n"
        }
        
        return report
    }
}

// MARK: - 调试工具

#if DEBUG

extension NSImage {
    
    /// 保存调试图像
    func debugSave(name: String) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("long_screenshot_debug_\(name).png")
        
        try? save(to: url)
        print("📸 调试图像已保存: \(url.path)")
    }
}

#endif

// MARK: - 内存管理

extension NSImage {
    
    /// 计算内存占用（字节）
    var memorySize: Int {
        guard let cgImage = cgImage else { return 0 }
        return cgImage.width * cgImage.height * 4  // RGBA
    }
    
    /// 压缩到指定内存大小
    func compressed(to maxBytes: Int) -> NSImage? {
        let currentSize = memorySize
        
        if currentSize <= maxBytes {
            return self
        }
        
        let factor = sqrt(Double(maxBytes) / Double(currentSize))
        return scaled(by: CGFloat(factor))
    }
}

// MARK: - 批量操作

extension Array where Element == NSImage {
    
    /// 批量调整大小
    func resized(to size: NSSize) -> [NSImage] {
        return compactMap { $0.resized(to: size) }
    }
    
    /// 批量裁剪
    func cropped(to rect: CGRect) -> [NSImage] {
        return compactMap { $0.cropped(to: rect) }
    }
    
    /// 批量保存
    func saveAll(to directory: URL, format: ImageFormat = .png) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        for (index, image) in enumerated() {
            let url = directory.appendingPathComponent("frame_\(String(format: "%04d", index)).\(format.fileExtension)")
            try image.save(to: url, format: format)
        }
    }
    
    /// 创建 GIF
    func createGIF(url: URL, delay: TimeInterval = 0.1, loopCount: Int = 0) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            kUTTypeGIF,
            count: count,
            nil
        ) else {
            throw ImageError.destinationCreationFailed
        }
        
        let gifProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: loopCount
            ]
        ]
        
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        for image in self {
            guard let cgImage = image.cgImage else { continue }
            
            let frameProperties: [CFString: Any] = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: delay
                ]
            ]
            
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }
        
        CGImageDestinationFinalize(destination)
    }
}
