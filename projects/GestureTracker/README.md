# GestureTracker - macOS 轨迹绘制与手势识别

类似 BetterAndBetter 的轨迹绘制功能实现。

## 功能特性

- ✅ 全局鼠标/触摸板事件监听
- ✅ 屏幕轨迹实时绘制
- ✅ 手势模板匹配识别
- ✅ 自定义手势动作绑定

## 系统要求

- macOS 10.15+
- Xcode 12+
- 需要辅助功能权限 (Accessibility)

## 使用方法

1. 在 `Info.plist` 添加权限说明
2. 运行程序后授权辅助功能
3. 按住右键拖动绘制轨迹

## 文件结构

```
GestureTracker/
├── GestureTracker.swift      # 主控制器
├── GestureOverlayView.swift  # 轨迹绘制视图
├── GestureRecognizer.swift   # 手势识别器
├── GestureTemplate.swift     # 手势模板
└── AppDelegate.swift         # 应用入口
```
