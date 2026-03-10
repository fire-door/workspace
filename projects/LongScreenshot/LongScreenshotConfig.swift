//
//  LongScreenshotConfig.swift
//  配置管理
//
//  功能：
//  1. 持久化配置
//  2. 默认值管理
//  3. 配置导入/导出
//

import Cocoa

// MARK: - 长截图配置

struct LongScreenshotConfig: Codable {
    
    // 截图设置
    var captureInterval: TimeInterval = 0.05      // 截图间隔（秒）
    var captureQuality: Double = 0.9              // 截图质量 (0-1)
    
    // 拼接设置
    var minOverlap: CGFloat = 50                  // 最小重叠区域
    var maxOverlap: CGFloat = 200                 // 最大重叠区域
    var matchThreshold: Double = 0.85             // 匹配阈值
    var stitchStrategy: StitchStrategy = .hybrid  // 拼接策略
    
    // 滚动设置
    var autoScroll: Bool = false                  // 自动滚动
    var scrollSpeed: CGFloat = 50                 // 滚动速度
    var scrollInterval: TimeInterval = 0.05       // 滚动间隔
    
    // 预览设置
    var showPreview: Bool = true                  // 显示预览
    var previewSize: CGFloat = 200                // 预览大小
    var showProgress: Bool = true                 // 显示进度
    
    // 输出设置
    var outputFormat: ImageFormat = .png          // 输出格式
    var outputQuality: Double = 0.9               // 输出质量
    var addWatermark: Bool = false                // 添加水印
    var watermarkText: String = ""                // 水印文本
    
    // 高级设置
    var maxMemory: Int = 500                      // 最大内存使用（MB）
    var enableGPU: Bool = true                    // 启用 GPU 加速
    var debugMode: Bool = false                   // 调试模式
    
    // MARK: - 预设配置
    
    static let `default` = LongScreenshotConfig()
    
    static let highQuality = LongScreenshotConfig(
        captureInterval: 0.03,
        captureQuality: 1.0,
        minOverlap: 80,
        maxOverlap: 300,
        matchThreshold: 0.9,
        stitchStrategy: .featureMatch,
        outputQuality: 1.0
    )
    
    static let fast = LongScreenshotConfig(
        captureInterval: 0.1,
        captureQuality: 0.7,
        minOverlap: 30,
        maxOverlap: 100,
        matchThreshold: 0.75,
        stitchStrategy: .templateMatch,
        scrollSpeed: 100
    )
    
    static let balanced = LongScreenshotConfig(
        captureInterval: 0.05,
        captureQuality: 0.85,
        minOverlap: 50,
        maxOverlap: 200,
        matchThreshold: 0.85,
        stitchStrategy: .hybrid
    )
}

// MARK: - 图像格式

enum ImageFormat: String, Codable {
    case png
    case jpeg
    case tiff
    case heic
    
    var fileExtension: String {
        return rawValue
    }
    
    var uti: String {
        switch self {
        case .png: return "public.png"
        case .jpeg: return "public.jpeg"
        case .tiff: return "public.tiff"
        case .heic: return "public.heic"
        }
    }
}

// MARK: - 拼接策略

enum StitchStrategy: String, Codable {
    case featureMatch   // 特征点匹配
    case templateMatch  // 模板匹配
    case perceptualHash // 感知哈希
    case hybrid         // 混合策略
    
    var description: String {
        switch self {
        case .featureMatch: return "特征点匹配（准确，慢）"
        case .templateMatch: return "模板匹配（快速，中等）"
        case .perceptualHash: return "感知哈希（中等）"
        case .hybrid: return "混合策略（推荐）"
        }
    }
}

// MARK: - 配置管理器

class LongScreenshotConfigManager {
    
    static let shared = LongScreenshotConfigManager()
    
    // 当前配置
    private(set) var config: LongScreenshotConfig = .default
    
    // 配置文件路径
    private let configFileURL: URL
    
    private init() {
        configFileURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw")
            .appendingPathComponent("long_screenshot_config.json")
        
        loadConfig()
    }
    
    // MARK: - 公开方法
    
    /// 更新配置
    func update(_ newConfig: LongScreenshotConfig) {
        config = newConfig
        saveConfig()
        
        // 发送通知
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }
    
    /// 更新部分配置
    func update(_ handler: (inout LongScreenshotConfig) -> Void) {
        handler(&config)
        saveConfig()
        
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }
    
    /// 重置为默认配置
    func reset() {
        config = .default
        saveConfig()
        
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }
    
    /// 导出配置
    func exportConfig(to url: URL) throws {
        let data = try JSONEncoder().encode(config)
        try data.write(to: url)
    }
    
    /// 导入配置
    func importConfig(from url: URL) throws {
        let data = try Data(contentsOf: url)
        config = try JSONDecoder().decode(LongScreenshotConfig.self, from: data)
        saveConfig()
        
        NotificationCenter.default.post(name: .configDidChange, object: nil)
    }
    
    /// 获取预设配置
    func getPreset(_ name: String) -> LongScreenshotConfig? {
        switch name {
        case "default": return .default
        case "highQuality": return .highQuality
        case "fast": return .fast
        case "balanced": return .balanced
        default: return nil
        }
    }
    
    // MARK: - 私有方法
    
    private func loadConfig() {
        guard FileManager.default.fileExists(atPath: configFileURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: configFileURL)
            config = try JSONDecoder().decode(LongScreenshotConfig.self, from: data)
        } catch {
            print("⚠️ 配置加载失败: \(error)")
        }
    }
    
    private func saveConfig() {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: configFileURL)
        } catch {
            print("⚠️ 配置保存失败: \(error)")
        }
    }
}

// MARK: - 通知扩展

extension Notification.Name {
    static let configDidChange = Notification.Name("configDidChange")
}

// MARK: - 配置验证

extension LongScreenshotConfig {
    
    /// 验证配置是否有效
    func validate() -> [String] {
        var errors: [String] = []
        
        if captureInterval < 0.01 || captureInterval > 1.0 {
            errors.append("截图间隔应在 0.01-1.0 秒之间")
        }
        
        if captureQuality < 0.1 || captureQuality > 1.0 {
            errors.append("截图质量应在 0.1-1.0 之间")
        }
        
        if minOverlap >= maxOverlap {
            errors.append("最小重叠应小于最大重叠")
        }
        
        if matchThreshold < 0.5 || matchThreshold > 1.0 {
            errors.append("匹配阈值应在 0.5-1.0 之间")
        }
        
        if scrollSpeed < 10 || scrollSpeed > 500 {
            errors.append("滚动速度应在 10-500 之间")
        }
        
        if maxMemory < 100 || maxMemory > 2000 {
            errors.append("最大内存应在 100-2000 MB 之间")
        }
        
        return errors
    }
    
    /// 调整配置以适应当前系统
    func adjustForSystem() -> LongScreenshotConfig {
        var adjusted = self
        
        // 根据可用内存调整
        let physicalMemory = ProcessInfo.processInfo.physicalMemory / 1024 / 1024 // MB
        
        if physicalMemory < 4096 {  // < 4GB
            adjusted.maxMemory = min(adjusted.maxMemory, 300)
            adjusted.captureQuality = min(adjusted.captureQuality, 0.8)
        }
        
        // 根据是否支持 GPU 调整
        // macOS 10.14+ 默认支持 Metal
        adjusted.enableGPU = adjusted.enableGPU
        
        return adjusted
    }
}

// MARK: - 配置描述

extension LongScreenshotConfig: CustomStringConvertible {
    var description: String {
        return """
        长截图配置:
        - 截图间隔: \(captureInterval)秒
        - 截图质量: \(Int(captureQuality * 100))%
        - 重叠范围: \(minOverlap)-\(maxOverlap)px
        - 匹配阈值: \(Int(matchThreshold * 100))%
        - 拼接策略: \(stitchStrategy.description)
        - 自动滚动: \(autoScroll ? "是" : "否")
        - 输出格式: \(outputFormat.fileExtension.uppercased())
        """
    }
}
