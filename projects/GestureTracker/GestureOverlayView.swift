//
//  GestureOverlayView.swift
//  轨迹绘制视图
//
//  功能：在屏幕上实时绘制手势轨迹
//

import Cocoa

class GestureOverlayView: NSView {
    
    // MARK: - 属性
    
    /// 轨迹颜色
    var pathColor: NSColor = NSColor.systemBlue.withAlphaComponent(0.8)
    
    /// 线宽
    var lineWidth: CGFloat = 3.0
    
    /// 轨迹点
    private var points: [CGPoint] = []
    
    /// 路径对象
    private var path: NSBezierPath?
    
    /// 动画渐变（轨迹尾部淡出效果）
    private var useGradientTrail = true
    private var trailLength: Int = 20
    
    // MARK: - 初始化
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    // MARK: - 公开方法
    
    /// 添加轨迹点
    func addPoint(_ point: CGPoint) {
        points.append(point)
        needsDisplay = true
    }
    
    /// 清除轨迹
    func clear() {
        points = []
        path = nil
        needsDisplay = true
    }
    
    /// 设置完整路径
    func setPath(_ newPoints: [CGPoint]) {
        points = newPoints
        needsDisplay = true
    }
    
    // MARK: - 绘制
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard !points.isEmpty else { return }
        
        NSGraphicsContext.saveGraphicsState()
        
        if useGradientTrail && points.count > 2 {
            drawGradientTrail()
        } else {
            drawSimplePath()
        }
        
        // 绘制起点和终点标记
        drawMarkers()
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    /// 绘制简单路径
    private func drawSimplePath() {
        let path = NSBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        path.move(to: points[0])
        for i in 1..<points.count {
            // 使用二次贝塞尔曲线平滑
            if i < points.count - 1 {
                let midPoint = CGPoint(
                    x: (points[i].x + points[i + 1].x) / 2,
                    y: (points[i].y + points[i + 1].y) / 2
                )
                path.curve(
                    to: midPoint,
                    controlPoint1: points[i],
                    controlPoint2: points[i]
                )
            } else {
                path.line(to: points[i])
            }
        }
        
        pathColor.setStroke()
        path.stroke()
        
        // 绘制外发光效果
        let glowPath = path.copy() as! NSBezierPath
        glowPath.lineWidth = lineWidth + 4
        pathColor.withAlphaComponent(0.3).setStroke()
        glowPath.stroke()
    }
    
    /// 绘制渐变轨迹（尾部淡出效果）
    private func drawGradientTrail() {
        let startIndex = max(0, points.count - trailLength * 3)
        
        for i in startIndex..<points.count - 1 {
            let alpha = CGFloat(i - startIndex) / CGFloat(points.count - startIndex)
            let color = pathColor.withAlphaComponent(alpha * 0.8 + 0.2)
            
            let segment = NSBezierPath()
            segment.lineWidth = lineWidth
            segment.lineCapStyle = .round
            
            segment.move(to: points[i])
            
            // 平滑曲线
            if i < points.count - 2 {
                let midPoint = CGPoint(
                    x: (points[i + 1].x + points[i + 2].x) / 2,
                    y: (points[i + 1].y + points[i + 2].y) / 2
                )
                segment.curve(
                    to: midPoint,
                    controlPoint1: points[i + 1],
                    controlPoint2: points[i + 1]
                )
            } else {
                segment.line(to: points[i + 1])
            }
            
            color.setStroke()
            segment.stroke()
        }
    }
    
    /// 绘制起点和终点标记
    private func drawMarkers() {
        guard points.count > 0 else { return }
        
        // 起点圆点
        let startPoint = points.first!
        let startDot = NSBezierPath(ovalIn: CGRect(
            x: startPoint.x - 6,
            y: startPoint.y - 6,
            width: 12,
            height: 12
        ))
        NSColor.green.withAlphaComponent(0.8).setFill()
        startDot.fill()
        
        // 终点圆点（如果路径足够长）
        if points.count > 10 {
            let endPoint = points.last!
            let endDot = NSBezierPath(ovalIn: CGRect(
                x: endPoint.x - 6,
                y: endPoint.y - 6,
                width: 12,
                height: 12
            ))
            NSColor.red.withAlphaComponent(0.8).setFill()
            endDot.fill()
        }
    }
    
    // MARK: - 轨迹优化
    
    /// 对轨迹点进行采样和简化
    func simplifyPath(points: [CGPoint], tolerance: CGFloat = 2.0) -> [CGPoint] {
        guard points.count > 2 else { return points }
        
        // Douglas-Peucker 算法
        return douglasPeucker(points: points, epsilon: tolerance)
    }
    
    private func douglasPeucker(points: [CGPoint], epsilon: CGFloat) -> [CGPoint] {
        if points.count <= 2 {
            return points
        }
        
        // 找到距离首尾连线最远的点
        var maxDistance: CGFloat = 0
        var maxIndex = 0
        
        for i in 1..<points.count - 1 {
            let distance = perpendicularDistance(
                point: points[i],
                lineStart: points.first!,
                lineEnd: points.last!
            )
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        // 如果最大距离大于阈值，递归简化
        if maxDistance > epsilon {
            let left = douglasPeucker(points: Array(points[0...maxIndex]), epsilon: epsilon)
            let right = douglasPeucker(points: Array(points[maxIndex..<points.count]), epsilon: epsilon)
            return left + right.dropFirst()
        } else {
            return [points.first!, points.last!]
        }
    }
    
    private func perpendicularDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> CGFloat {
        let dx = lineEnd.x - lineStart.x
        let dy = lineEnd.y - lineStart.y
        
        let lineLength = sqrt(dx * dx + dy * dy)
        if lineLength == 0 {
            return sqrt(pow(point.x - lineStart.x, 2) + pow(point.y - lineStart.y, 2))
        }
        
        let t = max(0, min(1, ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) / (lineLength * lineLength)))
        let projection = CGPoint(x: lineStart.x + t * dx, y: lineStart.y + t * dy)
        
        return sqrt(pow(point.x - projection.x, 2) + pow(point.y - projection.y, 2))
    }
}
