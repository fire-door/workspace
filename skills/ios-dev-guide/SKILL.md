---
name: ios-dev-guide
description: iOS/macOS 开发 Agent Skill 编写指南。用于创建 iOS 开发相关的 agent 和 skills，包括 Swift、Objective-C、SwiftUI、UIKit 等技术栈的项目配置、代码风格、测试和发布流程。
---

# iOS 开发 Agent Skill 编写指南

本指南帮助你为 iOS/macOS 项目创建专业的 agent 和 skills。

## 核心概念

### Agent vs Skill 的区别

| 概念 | 说明 | 示例 |
|------|------|------|
| **AGENTS.md** | 项目级配置，定义 agent 在你的仓库中如何工作 | 代码风格、构建命令、项目结构 |
| **SKILL.md** | 可复用的能力包，可跨项目使用 | Screen Time API、Core Data、网络层封装 |

### 什么时候用哪个？

- **AGENTS.md** — 针对特定项目的个性化配置
- **SKILL.md** — 可复用的专业知识，可以分享给其他项目

---

## 一、AGENTS.md 模板（iOS 项目）

将此文件放在项目根目录 `.github/AGENTS.md` 或直接 `AGENTS.md`：

```markdown
---
name: miaojie-ios-agent
description: 喵街 iOS 项目的开发助手，熟悉阿里技术栈和 iOS/macOS 原生开发
---

# 喵街 iOS 开发 Agent

## 技术栈

- **语言:** Swift 5.9, Objective-C (混编项目)
- **UI 框架:** UIKit (主力), SwiftUI (新功能)
- **架构:** MVVM + Coordinator
- **依赖管理:** CocoaPods (历史), SPM (新模块)
- **最低版本:** iOS 14.0
- **Xcode:** 15.2+

## 项目结构

```
MiaoJie/
├── App/                    # AppDelegate, SceneDelegate
├── Modules/                # 业务模块 (首页、购物车、我的)
├── Core/                   # 核心能力 (网络、路由、埋点)
├── Shared/                 # 共享组件
├── Resources/              # 资源文件
└── Tests/                  # 单元测试 & UI 测试
```

## 常用命令

### 构建 & 运行
```bash
# 打开项目
open MiaoJie.xcworkspace

# 命令行构建 (Debug)
xcodebuild -workspace MiaoJie.xcworkspace \
  -scheme MiaoJie \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 清理构建
xcodebuild clean -workspace MiaoJie.xcworkspace -scheme MiaoJie
```

### 测试
```bash
# 运行单元测试
xcodebuild test -workspace MiaoJie.xcworkspace \
  -scheme MiaoJie \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MiaoJieTests

# 运行 UI 测试
xcodebuild test -workspace MiaoJie.xcworkspace \
  -scheme MiaoJie \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MiaoJieUITests
```

### 依赖管理
```bash
# 安装 Pods
pod install

# 更新 Pods
pod update

# 检查过时的 Pods
pod outdated
```

## 代码风格示例

### Swift 命名规范

```swift
// ✅ 正确 - 清晰的命名，适当的访问控制
final class ProductListViewModel {
    private(set) var products: [Product] = []
    private let productService: ProductServicing
    private var cancellables = Set<AnyCancellable>()
    
    init(productService: ProductServicing = ProductService()) {
        self.productService = productService
    }
    
    @MainActor
    func loadProducts() async throws {
        products = try await productService.fetchProducts()
    }
}

// ✅ 正确 - 使用 mark 组织代码
// MARK: - Private Methods
private func configureCollectionView() {
    collectionView.register(ProductCell.self, forCellWithReuseIdentifier: "ProductCell")
    collectionView.dataSource = self
    collectionView.delegate = self
}

// ❌ 避免 - 模糊的命名
func get() async { ... }
var data: [Any] = []
```

### SwiftUI 风格

```swift
// ✅ 正确 - 视图拆分，清晰的预览
struct ProductListView: View {
    @StateObject private var viewModel: ProductListViewModel
    
    var body: some View {
        NavigationStack {
            contentView
                .task {
                    await viewModel.loadProducts()
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.products.isEmpty {
            emptyStateView
        } else {
            productListView
        }
    }
}

#Preview {
    ProductListView(viewModel: .init())
}
```

## 边界规则

### ✅ Always do
- 新文件添加到正确的 group/target
- 遵循现有的命名规范
- 使用 `final` 修饰不需要继承的类
- UI 相关代码确保 `@MainActor`
- 添加必要的单元测试

### ⚠️ Ask first
- 修改 Podfile 或添加新依赖
- 改变现有的架构模式
- 修改 Core 模块的核心逻辑
- 删除任何代码

### 🚫 Never do
- 直接修改 `Pods/` 目录
- 提交 `.xcuserstate` 或个人配置
- 在主线程执行耗时操作
- 使用强制解包 `!`（除非确定安全）

## Git 工作流

```bash
# 功能分支命名
feature/商品详情页优化
bugfix/修复购物车数量问题
hotfix/紧急修复闪退

# Commit 格式
feat(商品): 添加商品收藏功能
fix(购物车): 修复数量计算错误
refactor(网络): 重构请求重试逻辑
docs: 更新 README
```
```

---

## 二、SKILL.md 模板（iOS 专用技能）

### 示例 1：SwiftUI 组件技能

```markdown
---
name: swiftui-components
description: SwiftUI 组件开发专家。用于创建可复用的 SwiftUI 视图、修饰符和动画。触发条件：(1) 创建新的 SwiftUI 视图，(2) 设计自定义组件，(3) 实现复杂的 UI 交互，(4) 添加视图修饰符。
---

# SwiftUI 组件开发

## 核心原则

1. **视图拆分** - 单一职责，每个视图只做一件事
2. **状态驱动** - 使用 `@State`、`@Binding`、`@Observable`
3. **可预览** - 所有视图都应该有 `#Preview`
4. **可访问性** - 支持 Dynamic Type 和 VoiceOver

## 常用组件模板

### 列表单元格

```swift
struct ProductRowView: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: product.imageURL) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text(product.price, format: .currency(code: "CNY"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        ProductRowView(product: .mock)
    }
}
```

### 加载状态视图

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}

struct LoadingView<Content: View, T>: View {
    let state: LoadingState<T>
    let content: (T) -> Content
    
    var body: some View {
        switch state {
        case .idle:
            ContentUnavailableView("等待加载", systemImage: "clock")
        case .loading:
            ProgressView()
        case .loaded(let data):
            content(data)
        case .error(let error):
            ContentUnavailableView(
                "加载失败",
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription)
            )
        }
    }
}
```

## 动画最佳实践

```swift
// ✅ 使用 matchedGeometryEffect 实现转场
@Namespace private var namespace

// 列表中的缩略图
Image(product.image)
    .matchedGeometryEffect(id: product.id, in: namespace)

// 详情页中的大图
Image(product.image)
    .matchedGeometryEffect(id: product.id, in: namespace)

// ✅ 使用 transaction 控制动画
.transaction { transaction in
    transaction.animation = .spring(response: 0.3, dampingFraction: 0.8)
}
```

## 边界规则

- ✅ 使用 `@ViewBuilder` 组织复杂视图
- ✅ 提供 `#Preview` 用于所有视图
- ⚠️ 大型视图考虑拆分子视图
- 🚫 避免在视图内部进行网络请求
```

### 示例 2：网络层技能

```markdown
---
name: ios-networking
description: iOS 网络层架构专家。用于设计 API 客户端、处理认证、实现缓存和错误处理。触发条件：(1) 创建新的 API 服务，(2) 实现网络请求，(3) 处理认证/Token，(4) 设计缓存策略。
---

# iOS 网络层架构

## 推荐架构

```
NetworkLayer/
├── Core/
│   ├── NetworkClient.swift      # 核心请求客户端
│   ├── HTTPMethod.swift         # HTTP 方法枚举
│   └── NetworkError.swift       # 错误定义
├── Interceptors/
│   ├── AuthInterceptor.swift    # 认证拦截器
│   └── LoggingInterceptor.swift # 日志拦截器
├── Services/
│   ├── ProductService.swift     # 商品服务
│   └── UserService.swift        # 用户服务
└── Models/
    └── Request/                  # 请求模型
```

## 核心代码模板

### NetworkClient

```swift
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

final class NetworkClient: NetworkClientProtocol {
    private let session: URLSession
    private let baseURL: URL
    private var interceptors: [RequestInterceptor]
    
    init(
        baseURL: URL,
        session: URLSession = .shared,
        interceptors: [RequestInterceptor] = []
    ) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        var request = try endpoint.asURLRequest(baseURL: baseURL)
        
        // 应用拦截器
        for interceptor in interceptors {
            request = try interceptor.intercept(request)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw NetworkError.unauthorized
        default:
            throw NetworkError.statusCode(httpResponse.statusCode)
        }
    }
}
```

### Endpoint 协议

```swift
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Encodable? { get }
    
    func asURLRequest(baseURL: URL) throws -> URLRequest
}

extension Endpoint {
    func asURLRequest(baseURL: URL) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return request
    }
}
```

## 边界规则

- ✅ 所有网络请求必须有超时设置
- ✅ 敏感数据使用 Keychain 存储
- ⚠️ 修改 baseURL 需要确认
- 🚫 不要在主线程执行网络请求
- 🚫 不要硬编码 API Key
```

---

## 三、参考资源

### GitHub 上的优秀示例

1. **[dyxushuai/agent-skills](https://github.com/dyxushuai/agent-skills)** — AGENTS.md 模板和最佳实践
2. **[Siddhu7007/screen-time-api-agent-skill](https://github.com/Siddhu7007/screen-time-api-agent-skill)** — iOS Screen Time API 技能示例
3. **[GitHub 官方指南](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)** — 2500+ 仓库的经验总结

### 技能市场

- **[ClawHub](https://clawhub.ai)** — OpenClaw 官方技能市场

---

## 四、快速开始

### 为你的项目创建 AGENTS.md

```bash
# 在项目根目录创建
mkdir -p .github
touch .github/AGENTS.md
```

### 创建可复用的 Skill

```bash
# 创建技能目录
mkdir -p skills/my-ios-feature

# 创建 SKILL.md
cat > skills/my-ios-feature/SKILL.md << 'EOF'
---
name: my-ios-feature
description: 描述这个技能的作用和触发条件
---

# 技能标题

## 内容...
EOF
```

### 安装他人的技能

```bash
# 从 ClawHub 安装
clawhub install <skill-name>

# 从 GitHub 安装
npx skills add <owner>/<repo>
```

---

## 五、最佳实践总结

| 要点 | 说明 |
|------|------|
| **命令优先** | 把构建、测试命令放在最前面 |
| **示例胜于解释** | 用真实代码展示风格，不用抽象描述 |
| **设置边界** | 明确 Always/Ask first/Never |
| **版本明确** | 指定 Swift、Xcode、iOS 版本 |
| **六个核心区域** | 命令、测试、项目结构、代码风格、Git 工作流、边界 |
| **保持简洁** | SKILL.md 保持在 500 行以内 |
