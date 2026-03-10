//
//  BABGestureTracker.m
//  BetterAndBetter - Objective-C 实现
//
//  手势追踪与识别核心实现
//

#import "BABGestureTracker.h"
#import <ApplicationServices/ApplicationServices.h>

#pragma mark - BABGestureAction 实现

@implementation BABGestureAction

+ (instancetype)shortcutWithKeyCode:(CGKeyCode)keyCode modifiers:(NSEventModifierFlags)modifiers {
    BABGestureAction *action = [[BABGestureAction alloc] init];
    action.type = BABGestureActionTypeShortcut;
    action.keyCode = keyCode;
    action.modifiers = modifiers;
    return action;
}

+ (instancetype)appleScriptWithSource:(NSString *)source {
    BABGestureAction *action = [[BABGestureAction alloc] init];
    action.type = BABGestureActionTypeAppleScript;
    action.scriptSource = source;
    return action;
}

+ (instancetype)shellCommand:(NSString *)command {
    BABGestureAction *action = [[BABGestureAction alloc] init];
    action.type = BABGestureActionTypeShellCommand;
    action.command = command;
    return action;
}

+ (instancetype)launchAppWithBundleIdentifier:(NSString *)bundleIdentifier {
    BABGestureAction *action = [[BABGestureAction alloc] init];
    action.type = BABGestureActionTypeLaunchApp;
    action.bundleIdentifier = bundleIdentifier;
    return action;
}

@end

#pragma mark - BABGestureTemplate 实现

@implementation BABGestureTemplate

- (instancetype)initWithName:(NSString *)name points:(NSArray<NSValue *> *)points {
    self = [super init];
    if (self) {
        _name = [name copy];
        _points = [points copy];
    }
    return self;
}

@end

#pragma mark - 私有接口

@interface BABGestureTracker ()

@property (nonatomic, assign) BOOL isTracking;
@property (nonatomic, assign) BOOL isDrawing;
@property (nonatomic, strong) NSMutableArray<NSValue *> *pathPoints;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BABGestureAction *> *gestureActions;
@property (nonatomic, strong) NSMutableArray<BABGestureTemplate *> *templates;

@property (nonatomic, strong) NSWindow *overlayWindow;
@property (nonatomic, weak) NSView *overlayView;

@property (nonatomic, assign) CGEventTapProxy eventTap;
@property (nonatomic, assign) CFRunLoopSourceRef runLoopSource;

@end

#pragma mark - 主实现

@implementation BABGestureTracker

#pragma mark - 单例

+ (instancetype)sharedTracker {
    static BABGestureTracker *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BABGestureTracker alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _pathPoints = [NSMutableArray array];
        _gestureActions = [NSMutableDictionary dictionary];
        _templates = [NSMutableArray array];
        _confidenceThreshold = 0.7;
        
        [self setupOverlayWindow];
        [self loadDefaultTemplates];
    }
    return self;
}

- (void)dealloc {
    [self stopTracking];
}

#pragma mark - 控制方法

- (BOOL)startTracking {
    if (self.isTracking) {
        return YES;
    }
    
    // 检查辅助功能权限
    NSDictionary *options = @{(__bridge id)kAXTrustedCheckOptionPrompt: @YES};
    BOOL trusted = AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
    
    if (!trusted) {
        NSLog(@"⚠️ 需要辅助功能权限");
        return NO;
    }
    
    // 创建事件监听
    return [self setupEventTap];
}

- (void)stopTracking {
    if (!self.isTracking) {
        return;
    }
    
    if (_eventTap) {
        CGEventTapEnable(_eventTap, false);
        if (_runLoopSource) {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopDefaultMode);
        }
    }
    
    self.isTracking = NO;
}

#pragma mark - 手势绑定

- (void)bindAction:(BABGestureAction *)action toGesture:(NSString *)gestureName {
    self.gestureActions[gestureName] = action;
}

- (void)removeBindingForGesture:(NSString *)gestureName {
    [self.gestureActions removeObjectForKey:gestureName];
}

- (void)clearAllBindings {
    [self.gestureActions removeAllObjects];
}

#pragma mark - 模板管理

- (void)addTemplate:(BABGestureTemplate *)template {
    [self.templates addObject:template];
}

- (void)removeTemplateForName:(NSString *)name {
    [self.templates filterUsingPredicate:[NSPredicate predicateWithFormat:@"name != %@", name]];
}

- (void)clearTemplates {
    [self.templates removeAllObjects];
}

#pragma mark - 样式设置

- (void)setPathColor:(NSColor *)color width:(CGFloat)width {
    // 由 overlay view 实现
}

#pragma mark - 私有方法 - 窗口设置

- (void)setupOverlayWindow {
    NSScreen *screen = [NSScreen mainScreen];
    NSRect rect = screen.frame;
    
    _overlayWindow = [[NSWindow alloc] initWithContentRect:rect
                                                styleMask:NSWindowStyleMaskBorderless
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    
    _overlayWindow.level = NSScreenSaverWindowLevel;
    _overlayWindow.backgroundColor = [NSColor clearColor];
    _overlayWindow.ignoresMouseEvents = YES;
    _overlayWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    
    // 创建绘制视图
    NSView *view = [[NSView alloc] initWithFrame:rect];
    _overlayWindow.contentView = view;
    _overlayView = view;
}

#pragma mark - 私有方法 - 事件监听

- (BOOL)setupEventTap {
    // 监听的事件类型
    CGEventMask eventsToWatch = 
        (1 << kCGEventMouseDown) |
        (1 << kCGEventMouseUp) |
        (1 << kCGEventMouseDragged) |
        (1 << kCGEventOtherMouseDown) |
        (1 << kCGEventOtherMouseUp) |
        (1 << kCGEventOtherMouseDragged);
    
    // 创建事件回调
    CGEventTapCallBack callback = ^CGEventRef(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
        BABGestureTracker *tracker = (__bridge BABGestureTracker *)refcon;
        [tracker handleEventWithType:type event:event];
        return event;
    };
    
    // 创建事件Tap
    _eventTap = CGEventTapCreate(
        kCGSessionEventTap,
        kCGHeadInsertEventTap,
        kCGEventTapOptionDefault,
        eventsToWatch,
        callback,
        (__bridge void *)self
    );
    
    if (!_eventTap) {
        NSLog(@"❌ 无法创建事件监听");
        return NO;
    }
    
    _runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _eventTap, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), _runLoopSource, kCFRunLoopDefaultMode);
    CGEventTapEnable(_eventTap, true);
    
    self.isTracking = YES;
    return YES;
}

- (void)handleEventWithType:(CGEventType)type event:(CGEventRef)event {
    CGEventField buttonField = (CGEventField)886; // kCGMouseEventButtonNumber
    int64_t buttonNumber = CGEventGetIntegerValueField(event, buttonField);
    CGPoint location = CGEventGetLocation(event);
    
    switch (type) {
        case kCGEventOtherMouseDown:
        case kCGEventMouseDown:
            if (buttonNumber == 1) { // 右键
                [self startDrawingAt:location];
            }
            break;
            
        case kCGEventOtherMouseDragged:
        case kCGEventMouseDragged:
            if (self.isDrawing) {
                [self addPoint:location];
            }
            break;
            
        case kCGEventOtherMouseUp:
        case kCGEventMouseUp:
            if (self.isDrawing && buttonNumber == 1) {
                [self finishDrawing];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - 私有方法 - 绘制控制

- (void)startDrawingAt:(CGPoint)point {
    self.isDrawing = YES;
    [self.pathPoints removeAllObjects];
    [self.pathPoints addObject:[NSValue valueWithPoint:NSPointFromCGPoint(point)]];
    
    [_overlayWindow orderFrontRegardless];
    
    // 播放音效
    [[NSSound soundNamed:@"Pop"] play];
}

- (void)addPoint:(CGPoint)point {
    [self.pathPoints addObject:[NSValue valueWithPoint:NSPointFromCGPoint(point)]];
    
    if ([self.delegate respondsToSelector:@selector(gestureTrackerDidDrawPath:)]) {
        [self.delegate gestureTrackerDidDrawPath:self.pathPoints];
    }
}

- (void)finishDrawing {
    self.isDrawing = NO;
    
    // 延迟隐藏窗口
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.overlayWindow orderOut:nil];
    });
    
    // 识别手势
    if (self.pathPoints.count > 5) {
        NSDictionary *result = [self recognizePath:self.pathPoints];
        
        if (result) {
            NSString *name = result[@"name"];
            double confidence = [result[@"confidence"] doubleValue];
            
            NSLog(@"✅ 识别到手势: %@, 置信度: %.1f%%", name, confidence * 100);
            
            if ([self.delegate respondsToSelector:@selector(gestureTrackerDidRecognizeGesture:confidence:)]) {
                [self.delegate gestureTrackerDidRecognizeGesture:name confidence:confidence];
            }
            
            [self executeActionForGesture:name];
        }
    }
    
    [self.pathPoints removeAllObjects];
}

#pragma mark - 私有方法 - 手势识别

- (nullable NSDictionary *)recognizePath:(NSArray<NSValue *> *)path {
    // 简化实现：基于模板匹配
    // 完整实现需要 $1 Unistroke Recognizer 算法
    
    for (BABGestureTemplate *template in self.templates) {
        double similarity = [self calculateSimilarityBetween:path template:template.points];
        
        if (similarity >= self.confidenceThreshold) {
            return @{
                @"name": template.name,
                @"confidence": @(similarity)
            };
        }
    }
    
    return nil;
}

- (double)calculateSimilarityBetween:(NSArray<NSValue *> *)path1 template:(NSArray<NSValue *> *)path2 {
    // 简化版相似度计算
    // 实际应使用完整的 $1 识别器算法
    
    if (path1.count < 2 || path2.count < 2) {
        return 0;
    }
    
    // 重采样
    NSArray<NSValue *> *resampled1 = [self resamplePoints:path1 toCount:64];
    NSArray<NSValue *> *resampled2 = path2; // 模板已预处理
    
    // 计算平均距离
    double totalDistance = 0;
    NSUInteger count = MIN(resampled1.count, resampled2.count);
    
    for (NSUInteger i = 0; i < count; i++) {
        CGPoint p1 = [resampled1[i] pointValue];
        CGPoint p2 = [resampled2[i] pointValue];
        
        double dx = p1.x - p2.x;
        double dy = p1.y - p2.y;
        totalDistance += sqrt(dx * dx + dy * dy);
    }
    
    double avgDistance = totalDistance / count;
    
    // 转换为相似度 (0-1)
    double maxDistance = 200; // 归一化尺寸的对角线
    double similarity = 1.0 - (avgDistance / maxDistance);
    
    return MAX(0, MIN(1, similarity));
}

- (NSArray<NSValue *> *)resamplePoints:(NSArray<NSValue *> *)points toCount:(NSInteger)count {
    // 重采样算法
    NSMutableArray *result = [NSMutableArray array];
    
    if (points.count == 0) return result;
    
    CGFloat pathLength = [self calculatePathLength:points];
    CGFloat interval = pathLength / (count - 1);
    
    [result addObject:points.firstObject];
    CGFloat accumulatedDistance = 0;
    
    for (NSUInteger i = 1; i < points.count; i++) {
        CGPoint prev = [points[i-1] pointValue];
        CGPoint curr = [points[i] pointValue];
        
        CGFloat segmentDistance = [self distanceBetween:prev and:curr];
        
        if (accumulatedDistance + segmentDistance >= interval) {
            CGFloat ratio = (interval - accumulatedDistance) / segmentDistance;
            CGPoint newPoint = CGPointMake(
                prev.x + ratio * (curr.x - prev.x),
                prev.y + ratio * (curr.y - prev.y)
            );
            [result addObject:[NSValue valueWithPoint:newPoint]];
            accumulatedDistance = 0;
        } else {
            accumulatedDistance += segmentDistance;
        }
    }
    
    // 确保足够点数
    while (result.count < count) {
        [result addObject:points.lastObject];
    }
    
    return result;
}

- (CGFloat)calculatePathLength:(NSArray<NSValue *> *)points {
    CGFloat length = 0;
    for (NSUInteger i = 1; i < points.count; i++) {
        CGPoint p1 = [points[i-1] pointValue];
        CGPoint p2 = [points[i] pointValue];
        length += [self distanceBetween:p1 and:p2];
    }
    return length;
}

- (CGFloat)distanceBetween:(CGPoint)p1 and:(CGPoint)p2 {
    CGFloat dx = p2.x - p1.x;
    CGFloat dy = p2.y - p1.y;
    return sqrt(dx * dx + dy * dy);
}

#pragma mark - 私有方法 - 动作执行

- (void)executeActionForGesture:(NSString *)gestureName {
    BABGestureAction *action = self.gestureActions[gestureName];
    
    if (!action) {
        NSLog(@"⚠️ 手势 '%@' 未绑定动作", gestureName);
        return;
    }
    
    switch (action.type) {
        case BABGestureActionTypeShortcut:
            [self executeShortcutWithKeyCode:action.keyCode modifiers:action.modifiers];
            break;
            
        case BABGestureActionTypeAppleScript:
            [self executeAppleScript:action.scriptSource];
            break;
            
        case BABGestureActionTypeShellCommand:
            [self executeShellCommand:action.command];
            break;
            
        case BABGestureActionTypeLaunchApp:
            [self launchAppWithBundleIdentifier:action.bundleIdentifier];
            break;
            
        default:
            break;
    }
}

- (void)executeShortcutWithKeyCode:(CGKeyCode)keyCode modifiers:(NSEventModifierFlags)modifiers {
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, keyCode, true);
    CGEventSetFlags(keyDown, (CGEventFlags)modifiers);
    CGEventPost(kCGHIDEventTap, keyDown);
    CFRelease(keyDown);
    
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, keyCode, false);
    CGEventSetFlags(keyUp, (CGEventFlags)modifiers);
    CGEventPost(kCGHIDEventTap, keyUp);
    CFRelease(keyUp);
    
    CFRelease(source);
}

- (void)executeAppleScript:(NSString *)source {
    NSDictionary *errorInfo = nil;
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:source];
    [script executeAndReturnError:&errorInfo];
    
    if (errorInfo) {
        NSLog(@"❌ AppleScript 执行失败: %@", errorInfo);
    }
}

- (void)executeShellCommand:(NSString *)command {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/bash";
        task.arguments = @[@"-c", command];
        
        @try {
            [task launch];
            [task waitUntilExit];
        } @catch (NSException *exception) {
            NSLog(@"❌ Shell 命令执行失败: %@", exception);
        }
    });
}

- (void)launchAppWithBundleIdentifier:(NSString *)bundleIdentifier {
    NSURL *url = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier:bundleIdentifier];
    
    if (!url) {
        NSLog(@"❌ 未找到应用: %@", bundleIdentifier);
        return;
    }
    
    NSWorkspaceOpenConfiguration *config = [[NSWorkspaceOpenConfiguration alloc] init];
    [NSWorkspace.sharedWorkspace openApplicationAtURL:url configuration:config completionHandler:nil];
}

#pragma mark - 私有方法 - 默认模板

- (void)loadDefaultTemplates {
    // 圆形
    [self addTemplate:[self createCircleTemplate]];
    
    // 方向箭头
    [self addTemplate:[[BABGestureTemplate alloc] initWithName:@"right"
                                                        points:[self createArrowRightTemplate]]];
    [self addTemplate:[[BABGestureTemplate alloc] initWithName:@"left"
                                                        points:[self createArrowLeftTemplate]]];
    [self addTemplate:[[BABGestureTemplate alloc] initWithName:@"up"
                                                        points:[self createArrowUpTemplate]]];
    [self addTemplate:[[BABGestureTemplate alloc] initWithName:@"down"
                                                        points:[self createArrowDownTemplate]]];
}

- (BABGestureTemplate *)createCircleTemplate {
    NSMutableArray *points = [NSMutableArray array];
    for (int i = 0; i < 32; i++) {
        CGFloat angle = i * 2 * M_PI / 32;
        CGPoint point = CGPointMake(cos(angle), sin(angle));
        [points addObject:[NSValue valueWithPoint:point]];
    }
    return [[BABGestureTemplate alloc] initWithName:@"circle" points:points];
}

- (NSArray<NSValue *> *)createArrowRightTemplate {
    return @[
        [NSValue valueWithPoint:CGPointMake(-1, 0)],
        [NSValue valueWithPoint:CGPointMake(1, 0)]
    ];
}

- (NSArray<NSValue *> *)createArrowLeftTemplate {
    return @[
        [NSValue valueWithPoint:CGPointMake(1, 0)],
        [NSValue valueWithPoint:CGPointMake(-1, 0)]
    ];
}

- (NSArray<NSValue *> *)createArrowUpTemplate {
    return @[
        [NSValue valueWithPoint:CGPointMake(0, -1)],
        [NSValue valueWithPoint:CGPointMake(0, 1)]
    ];
}

- (NSArray<NSValue *> *)createArrowDownTemplate {
    return @[
        [NSValue valueWithPoint:CGPointMake(0, 1)],
        [NSValue valueWithPoint:CGPointMake(0, -1)]
    ];
}

@end
