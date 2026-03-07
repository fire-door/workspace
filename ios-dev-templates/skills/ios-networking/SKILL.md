---
name: ios-networking
description: iOS 网络层架构专家。用于设计 API 客户端、处理认证、实现缓存和错误处理。触发条件：(1) 创建新的 API 服务，(2) 实现网络请求，(3) 处理认证/Token，(4) 设计缓存策略，(5) 错误处理和重试机制。
---

# iOS 网络层架构

你是 iOS 网络层架构专家。你熟悉 URLSession、Alamofire、以及阿里 MTOP 等网络库的最佳实践。

## 推荐架构

```
NetworkLayer/
├── Core/
│   ├── NetworkClient.swift          # 核心请求客户端
│   ├── NetworkClientProtocol.swift  # 协议定义
│   ├── HTTPMethod.swift             # HTTP 方法枚举
│   ├── NetworkError.swift           # 错误定义
│   └── NetworkConfiguration.swift   # 配置
│
├── Interceptors/
│   ├── RequestInterceptor.swift     # 请求拦截器协议
│   ├── AuthInterceptor.swift        # 认证拦截器
│   ├── LoggingInterceptor.swift     # 日志拦截器
│   └── RetryInterceptor.swift       # 重试拦截器
│
├── Endpoint/
│   ├── Endpoint.swift               # Endpoint 协议
│   └── Endpoints/                   # 具体 API 定义
│       ├── ProductEndpoint.swift
│       ├── UserEndpoint.swift
│       └── OrderEndpoint.swift
│
├── Services/
│   ├── ProductService.swift         # 商品服务
│   ├── UserService.swift            # 用户服务
│   └── OrderService.swift           # 订单服务
│
├── Models/
│   ├── Request/                     # 请求模型
│   └── Response/                    # 响应模型
│
└── Cache/
    ├── ResponseCache.swift          # 响应缓存
    └── ImageCache.swift             # 图片缓存
```

## 核心代码

### NetworkClient

```swift
import Foundation

// MARK: - Protocol

protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable & Sendable>(_ endpoint: any Endpoint) async throws -> T
    func request(_ endpoint: any Endpoint) async throws -> Data
}

// MARK: - Implementation

final class NetworkClient: NetworkClientProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let configuration: NetworkConfiguration
    private var interceptors: [any RequestInterceptor]
    
    // MARK: - Initialization
    
    init(
        configuration: NetworkConfiguration = .default,
        session: URLSession = .shared,
        interceptors: [any RequestInterceptor] = []
    ) {
        self.configuration = configuration
        self.session = session
        self.interceptors = interceptors
    }
    
    // MARK: - Public Methods
    
    func request<T: Decodable & Sendable>(_ endpoint: any Endpoint) async throws -> T {
        let data = try await request(endpoint)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    func request(_ endpoint: any Endpoint) async throws -> Data {
        var request = try buildRequest(for: endpoint)
        
        // 应用拦截器
        for interceptor in interceptors {
            request = try await interceptor.intercept(request)
        }
        
        // 日志
        logRequest(request)
        
        // 发送请求
        let (data, response) = try await session.data(for: request)
        
        // 验证响应
        try validate(response: response, data: data)
        
        return data
    }
    
    // MARK: - Private Methods
    
    private func buildRequest(for endpoint: any Endpoint) throws -> URLRequest {
        let url = configuration.baseURL.appendingPathComponent(endpoint.path)
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = endpoint.queryItems
        
        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers ?? [:]
        request.timeoutInterval = endpoint.timeout ?? configuration.timeout
        
        // 添加通用 Headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.userAgent, forHTTPHeaderField: "User-Agent")
        
        // Body
        if let body = endpoint.body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } catch {
                throw NetworkError.encodingFailed(error)
            }
        }
        
        return request
    }
    
    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400..<500:
            if let errorMessage = String(data: data, encoding: .utf8) {
                throw NetworkError.clientError(statusCode: httpResponse.statusCode, message: errorMessage)
            }
            throw NetworkError.clientError(statusCode: httpResponse.statusCode, message: nil)
        case 500..<600:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw NetworkError.unknown
        }
    }
    
    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        print("🌐 [\(request.httpMethod ?? "")] \(request.url?.absoluteString ?? "")")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
        #endif
    }
}
```

### Endpoint 协议

```swift
import Foundation

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Encodable? { get }
    var timeout: TimeInterval? { get }
}

extension Endpoint {
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Encodable? { nil }
    var timeout: TimeInterval? { nil }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
```

### Network Error

```swift
import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingFailed(Error)
    case decodingFailed(Error)
    case unauthorized
    case forbidden
    case notFound
    case clientError(statusCode: Int, message: String?)
    case serverError(statusCode: Int)
    case noNetwork
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的请求地址"
        case .invalidResponse:
            return "服务器响应异常"
        case .encodingFailed(let error):
            return "请求编码失败: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .forbidden:
            return "没有权限访问"
        case .notFound:
            return "请求的资源不存在"
        case .clientError(_, let message):
            return message ?? "请求错误"
        case .serverError:
            return "服务器错误，请稍后重试"
        case .noNetwork:
            return "网络不可用，请检查网络连接"
        case .timeout:
            return "请求超时，请重试"
        case .unknown:
            return "未知错误"
        }
    }
}
```

### 拦截器

```swift
import Foundation

// MARK: - Protocol

protocol RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest
}

// MARK: - Auth Interceptor

final class AuthInterceptor: RequestInterceptor {
    private let tokenStorage: TokenStoring
    
    init(tokenStorage: TokenStoring) {
        self.tokenStorage = tokenStorage
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        var request = request
        
        // 跳过不需要认证的接口
        if shouldSkipAuth(for: request) {
            return request
        }
        
        // 添加 Token
        if let token = tokenStorage.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func shouldSkipAuth(for request: URLRequest) -> Bool {
        guard let path = request.url?.path else { return false }
        
        let noAuthPaths = [
            "/auth/login",
            "/auth/register",
            "/auth/refresh",
        ]
        
        return noAuthPaths.contains { path.contains($0) }
    }
}

// MARK: - Retry Interceptor

final class RetryInterceptor: RequestInterceptor {
    private let maxRetries: Int
    private let retryDelay: TimeInterval
    
    init(maxRetries: Int = 3, retryDelay: TimeInterval = 1.0) {
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        // 这个拦截器主要用于在请求失败后重试
        // 实际重试逻辑需要在 NetworkClient 中实现
        return request
    }
}

// MARK: - Logging Interceptor

final class LoggingInterceptor: RequestInterceptor {
    func intercept(_ request: URLRequest) async throws -> URLRequest {
        #if DEBUG
        let timestamp = Date()
        print("📤 [\(timestamp)] \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")")
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("📋 Headers: \(headers)")
        }
        
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("📦 Body: \(bodyString)")
        }
        #endif
        
        return request
    }
}
```

### 具体服务实现

```swift
import Foundation

// MARK: - Product Endpoint

enum ProductEndpoint {
    case list(page: Int, pageSize: Int)
    case detail(id: String)
    case search(keyword: String, page: Int)
    case favorite(id: String)
    case unfavorite(id: String)
}

extension ProductEndpoint: Endpoint {
    var path: String {
        switch self {
        case .list:
            return "/products"
        case .detail(let id):
            return "/products/\(id)"
        case .search:
            return "/products/search"
        case .favorite(let id):
            return "/products/\(id)/favorite"
        case .unfavorite(let id):
            return "/products/\(id)/unfavorite"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .list, .detail, .search:
            return .get
        case .favorite, .unfavorite:
            return .post
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .list(let page, let pageSize):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "pageSize", value: "\(pageSize)")
            ]
        case .search(let keyword, let page):
            return [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "page", value: "\(page)")
            ]
        default:
            return nil
        }
    }
}

// MARK: - Product Service

protocol ProductServiceProtocol {
    func fetchProducts(page: Int, pageSize: Int) async throws -> ProductListResponse
    func fetchProduct(id: String) async throws -> Product
    func searchProducts(keyword: String, page: Int) async throws -> ProductListResponse
    func toggleFavorite(productId: String, isFavorite: Bool) async throws
}

final class ProductService: ProductServiceProtocol {
    private let client: NetworkClientProtocol
    
    init(client: NetworkClientProtocol) {
        self.client = client
    }
    
    func fetchProducts(page: Int, pageSize: Int) async throws -> ProductListResponse {
        try await client.request(.list(page: page, pageSize: pageSize))
    }
    
    func fetchProduct(id: String) async throws -> Product {
        try await client.request(.detail(id: id))
    }
    
    func searchProducts(keyword: String, page: Int) async throws -> ProductListResponse {
        try await client.request(.search(keyword: keyword, page: page))
    }
    
    func toggleFavorite(productId: String, isFavorite: Bool) async throws {
        let endpoint: Endpoint = isFavorite
            ? ProductEndpoint.favorite(id: productId)
            : ProductEndpoint.unfavorite(id: productId)
        
        let _: EmptyResponse = try await client.request(endpoint)
    }
}

// MARK: - Response Models

struct ProductListResponse: Decodable {
    let products: [Product]
    let total: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

struct Product: Decodable, Identifiable {
    let id: String
    let name: String
    let price: Double
    let originalPrice: Double
    let imageURL: URL
    let tags: [String]
}

struct EmptyResponse: Decodable {}
```

## 使用示例

```swift
// 在 ViewModel 中使用
@MainActor
final class ProductListViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let productService: ProductServiceProtocol
    private var currentPage = 1
    private var hasMore = true
    
    // MARK: - Initialization
    
    init(productService: ProductServiceProtocol) {
        self.productService = productService
    }
    
    // MARK: - Public Methods
    
    func loadProducts() async {
        guard !isLoading, hasMore else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await productService.fetchProducts(
                page: currentPage,
                pageSize: 20
            )
            
            if currentPage == 1 {
                products = response.products
            } else {
                products.append(contentsOf: response.products)
            }
            
            currentPage += 1
            hasMore = response.hasMore
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func refresh() async {
        currentPage = 1
        hasMore = true
        await loadProducts()
    }
}
```

## 边界规则

### ✅ Always do
- 所有请求设置合理的超时时间
- 敏感数据使用 Keychain 存储
- 错误信息对用户友好
- Debug 模式下打印请求日志

### ⚠️ Ask first
- 修改 baseURL
- 添加新的拦截器
- 修改缓存策略

### 🚫 Never do
- 在主线程执行网络请求
- 硬编码 API Key 或 Token
- 忽略 SSL 证书验证
- 不处理错误情况
