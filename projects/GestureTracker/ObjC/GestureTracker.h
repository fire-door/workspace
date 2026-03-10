//
//  BABGestureTracker.h
//  BetterAndBetter - Objective-C 实现
//
//  手势追踪与识别核心类
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 手势动作类型

typedef NS_ENUM(NSInteger, BABGestureActionType) {
    BABGestureActionTypeNone = 0,
    BABGestureActionTypeShortcut,
    BABGestureActionTypeAppleScript,
    BABGestureActionTypeShellCommand,
    BABGestureActionTypeLaunchApp,
};

#pragma mark - 手势动作

@interface BABGestureAction : NSObject

@property (nonatomic, assign) BABGestureActionType type;
@property (nonatomic, assign) CGKeyCode keyCode;
@property (nonatomic, assign) NSEventModifierFlags modifiers;
@property (nonatomic, copy, nullable) NSString *scriptSource;
@property (nonatomic, copy, nullable) NSString *command;
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;

// 便捷构造方法
+ (instancetype)shortcutWithKeyCode:(CGKeyCode)keyCode modifiers:(NSEventModifierFlags)modifiers;
+ (instancetype)appleScriptWithSource:(NSString *)source;
+ (instancetype)shellCommand:(NSString *)command;
+ (instancetype)launchAppWithBundleIdentifier:(NSString *)bundleIdentifier;

@end

#pragma mark - 手势模板

@interface BABGestureTemplate : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray<NSValue *> *points; // NSValue包装的CGPoint

- (instancetype)initWithName:(NSString *)name points:(NSArray<NSValue *> *)points;

@end

#pragma mark - 代理协议

@protocol BABGestureTrackerDelegate <NSObject>

@optional
- (void)gestureTrackerDidRecognizeGesture:(NSString *)gestureName confidence:(double)confidence;
- (void)gestureTrackerDidDrawPath:(NSArray<NSValue *> *)path;

@end

#pragma mark - 主类

@interface BABGestureTracker : NSObject

/// 单例
+ (instancetype)sharedTracker;

/// 代理
@property (nonatomic, weak, nullable) id<BABGestureTrackerDelegate> delegate;

/// 是否正在追踪
@property (nonatomic, readonly) BOOL isTracking;

/// 是否正在绘制
@property (nonatomic, readonly) BOOL isDrawing;

/// 置信度阈值 (0.0 - 1.0)
@property (nonatomic, assign) double confidenceThreshold;

#pragma mark - 控制

/// 开始追踪（返回是否成功）
- (BOOL)startTracking;

/// 停止追踪
- (void)stopTracking;

#pragma mark - 手势绑定

/// 绑定动作到手势
- (void)bindAction:(BABGestureAction *)action toGesture:(NSString *)gestureName;

/// 移除绑定
- (void)removeBindingForGesture:(NSString *)gestureName;

/// 清除所有绑定
- (void)clearAllBindings;

#pragma mark - 模板管理

/// 添加手势模板
- (void)addTemplate:(BABGestureTemplate *)template;

/// 移除手势模板
- (void)removeTemplateForName:(NSString *)name;

/// 清除所有模板
- (void)clearTemplates;

#pragma mark - 样式设置

/// 设置轨迹颜色和线宽
- (void)setPathColor:(NSColor *)color width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
