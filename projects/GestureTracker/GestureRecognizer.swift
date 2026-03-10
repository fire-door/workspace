//
//  GestureRecognizer.swift
//  手势识别器
//
//  功能：使用 $1 Unistroke Recognizer 算法识别手势
//  参考：https://depts.washington.edu/acelab/proj/dollar/index.html
//

import Foundation
import Cocoa

// MARK: - 手势模板
struct GestureTemplate {
    let name: String
    let points: [CGPoint]
    
    init(name: String, points: [CGPoint]) {
        self.name = name
        self.points = GestureRecognizer.resample(points, to: 64)
    }
}

// MARK: - 手势识别器
class GestureRecognizer {
    
    // 模板库
    private var templates: [GestureTemplate] = []
    
    // 识别参数
    private let numPoints = 64          // 采样点数
    private let squareSize: CGFloat = 250  // 归一化尺寸
    private let angleRange: CGFloat = 45    // 角度搜索范围（度）
    private let anglePrecision: CGFloat = 2 // 角度精度（度）
    private let halfDiagonal = sqrt(2) * 250 / 2
    
    // 置信度阈值
    var confidenceThreshold: Double = 0.7
    
    // MARK: - 模板管理
    
    func addTemplate(_ template: GestureTemplate) {
        templates.append(template)
    }
    
    func addTemplates(_ newTemplates: [GestureTemplate]) {
        templates.append(contentsOf: newTemplates)
    }
    
    func removeTemplate(named name: String) {
        templates.removeAll { $0.name == name }
    }
    
    func clearTemplates() {
        templates = []
    }
    
    // MARK: - 识别
    
    /// 识别手势
    /// - Parameter path: 用户绘制的轨迹点
    /// - Returns: (手势名称, 置信度) 或 nil
    func recognize(path: [CGPoint]) -> (String, Double)? {
        guard !templates.isEmpty else {
            print("⚠️ 没有加载手势模板")
            return nil
        }
        
        guard path.count > 5 else {
            print("⚠️ 轨迹点太少")
            return nil
        }
        
        // 预处理：重采样
        let points = GestureRecognizer.resample(path, to: numPoints)
        
        // 预处理：旋转到指示性角度
        let radians = indicativeAngle(points: points)
        var normalized = rotate(by: -radians, points: points)
        
        // 预处理：缩放到标准正方形
        normalized = scaleToSquare(points: normalized)
        
        // 预处理：平移到原点
        normalized = translateToOrigin(points: normalized)
        
        // 与所有模板比对
        var bestMatch: (String, Double)?
        var bestDistance = CGFloat.infinity
        
        for template in templates {
            let distance = distanceAtBestAngle(
                points: normalized,
                template: template.points
            )
            
            if distance < bestDistance {
                bestDistance = distance
                let confidence = 1 - (distance / halfDiagonal)
                bestMatch = (template.name, Double(confidence))
            }
        }
        
        // 检查置信度
        if let match = bestMatch, match.1 >= confidenceThreshold {
            return match
        }
        
        return nil
    }
    
    // MARK: - 预处理算法
    
    /// 重采样到固定点数
    static func resample(_ points: [CGPoint], to n: Int) -> [CGPoint] {
        guard points.count > 1 else { return points }
        
        let interval = pathLength(points) / CGFloat(n - 1)
        var result: [CGPoint] = [points[0]]
        var accumulatedDistance: CGFloat = 0
        
        for i in 1..<points.count {
            let segmentDistance = distance(points[i-1], points[i])
            
            if accumulatedDistance + segmentDistance >= interval {
                let ratio = (interval - accumulatedDistance) / segmentDistance
                let newPoint = CGPoint(
                    x: points[i-1].x + ratio * (points[i].x - points[i-1].x),
                    y: points[i-1].y + ratio * (points[i].y - points[i-1].y)
                )
                result.append(newPoint)
                accumulatedDistance = 0
            } else {
                accumulatedDistance += segmentDistance
            }
        }
        
        // 确保有足够的点
        while result.count < n {
            result.append(points.last!)
        }
        
        return result
    }
    
    /// 计算路径总长度
    private static func pathLength(_ points: [CGPoint]) -> CGFloat {
        var length: CGFloat = 0
        for i in 1..<points.count {
            length += distance(points[i-1], points[i])
        }
        return length
    }
    
    /// 计算两点距离
    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
    }
    
    /// 计算指示性角度（质心到第一个点的角度）
    private func indicativeAngle(points: [CGPoint]) -> CGFloat {
        let centroid = computeCentroid(points)
        return atan2(points[0].y - centroid.y, points[0].x - centroid.x)
    }
    
    /// 计算质心
    private func computeCentroid(_ points: [CGPoint]) -> CGPoint {
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        for p in points {
            sumX += p.x
            sumY += p.y
        }
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }
    
    /// 旋转点集
    private func rotate(by radians: CGFloat, points: [CGPoint]) -> [CGPoint] {
        let centroid = computeCentroid(points)
        let cos = Foundation.cos(radians)
        let sin = Foundation.sin(radians)
        
        return points.map { p in
            CGPoint(
                x: (p.x - centroid.x) * cos - (p.y - centroid.y) * sin + centroid.x,
                y: (p.x - centroid.x) * sin + (p.y - centroid.y) * cos + centroid.y
            )
        }
    }
    
    /// 缩放到标准正方形
    private func scaleToSquare(points: [CGPoint]) -> [CGPoint] {
        let box = boundingBox(points)
        
        return points.map { p in
            CGPoint(
                x: (p.x - box.minX) / box.width * squareSize,
                y: (p.y - box.minY) / box.height * squareSize
            )
        }
    }
    
    /// 计算包围盒
    private func boundingBox(_ points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        var minX = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var minY = CGFloat.infinity
        var maxY = -CGFloat.infinity
        
        for p in points {
            minX = min(minX, p.x)
            maxX = max(maxX, p.x)
            minY = min(minY, p.y)
            maxY = max(maxY, p.y)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    /// 平移到原点
    private func translateToOrigin(points: [CGPoint]) -> [CGPoint] {
        let centroid = computeCentroid(points)
        return points.map { CGPoint(x: $0.x - centroid.x, y: $0.y - centroid.y) }
    }
    
    // MARK: - 距离计算
    
    /// 在最佳角度下计算距离
    private func distanceAtBestAngle(points: [CGPoint], template: [CGPoint]) -> CGFloat {
        let radians = angleRange * .pi / 180
        let precision = anglePrecision * .pi / 180
        
        // 黄金分割搜索
        let phi = 0.5 * (-1 + sqrt(5))
        
        var a = -radians
        var b = radians
        var c = b - phi * (b - a)
        var d = a + phi * (b - a)
        
        while abs(b - a) > precision {
            let distC = pathDistance(points, template, c)
            let distD = pathDistance(points, template, d)
            
            if distC < distD {
                b = d
                d = c
                c = b - phi * (b - a)
            } else {
                a = c
                c = d
                d = a + phi * (b - a)
            }
        }
        
        return min(pathDistance(points, template, (a + b) / 2), halfDiagonal)
    }
    
    /// 计算旋转后的路径距离
    private func pathDistance(_ pts1: [CGPoint], _ pts2: [CGPoint], _ radians: CGFloat) -> CGFloat {
        let rotated = rotate(by: radians, points: pts1)
        var sum: CGFloat = 0
        
        for i in 0..<min(rotated.count, pts2.count) {
            sum += GestureRecognizer.distance(rotated[i], pts2[i])
        }
        
        return sum / CGFloat(min(rotated.count, pts2.count))
    }
}
