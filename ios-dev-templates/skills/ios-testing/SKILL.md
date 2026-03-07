---
name: ios-testing
description: iOS 测试专家。用于编写单元测试、UI 测试、性能测试和 mock 数据。触发条件：(1) 编写单元测试，(2) 实现 UI 测试，(3) Mock 网络请求，(4) 测试覆盖率优化，(5) 性能测试。
---

# iOS 测试

你是 iOS 测试专家。你熟悉 XCTest、XCTest 框架、以及测试驱动开发 (TDD) 的最佳实践。

## 测试架构

```
Tests/
├── MiaoJieTests/                    # 单元测试
│   ├── ViewModels/
│   │   ├── ProductListViewModelTests.swift
│   │   └── ProductDetailViewModelTests.swift
│   ├── Services/
│   │   ├── ProductServiceTests.swift
│   │   └── AuthServiceTests.swift
│   ├── Models/
│   │   └── ProductTests.swift
│   └── Helpers/
│       ├── Mocks/
│       │   ├── MockProductService.swift
│       │   └── MockNetworkClient.swift
│       └── TestData/
│           └── ProductTestData.swift
│
└── MiaoJieUITests/                  # UI 测试
    ├── Flows/
    │   ├── LoginFlowTests.swift
    │   └── PurchaseFlowTests.swift
    └── Screens/
        ├── ProductListScreenTests.swift
        └── ProductDetailScreenTests.swift
```

## 单元测试模板

### ViewModel 测试

```swift
import XCTest
@testable import MiaoJie

final class ProductListViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ProductListViewModel!
    private var mockProductService: MockProductService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockProductService = MockProductService()
        sut = ProductListViewModel(productService: mockProductService)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockProductService = nil
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(sut.products.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Load Products Tests
    
    func testLoadProductsSuccess() async throws {
        // Given
        let expectedProducts = Product.mockList
        mockProductService.fetchProductsResult = .success(
            ProductListResponse(
                products: expectedProducts,
                total: expectedProducts.count,
                page: 1,
                pageSize: 20,
                hasMore: false
            )
        )
        
        // When
        await sut.loadProducts()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.products.count, expectedProducts.count)
        XCTAssertNil(sut.error)
        XCTAssertTrue(mockProductService.fetchProductsCalled)
    }
    
    func testLoadProductsFailure() async throws {
        // Given
        mockProductService.fetchProductsResult = .failure(NetworkError.noNetwork)
        
        // When
        await sut.loadProducts()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.products.isEmpty)
        XCTAssertNotNil(sut.error)
    }
    
    func testLoadProductsSetsLoadingState() async throws {
        // Given
        mockProductService.fetchProductsDelay = 0.5
        
        // When
        let task = Task { await sut.loadProducts() }
        
        // Then - 立即检查 loading 状态
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        XCTAssertTrue(sut.isLoading)
        
        // Wait for completion
        await task.value
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Pagination Tests
    
    func testLoadMoreProductsAppendsToList() async throws {
        // Given
        let firstPage = Array(Product.mockList.prefix(10))
        let secondPage = Array(Product.mockList.suffix(10))
        
        mockProductService.fetchProductsResult = .success(
            ProductListResponse(products: firstPage, total: 20, page: 1, pageSize: 10, hasMore: true)
        )
        
        // When - 加载第一页
        await sut.loadProducts()
        
        // Then
        XCTAssertEqual(sut.products.count, 10)
        
        // Given - 模拟第二页
        mockProductService.fetchProductsResult = .success(
            ProductListResponse(products: secondPage, total: 20, page: 2, pageSize: 10, hasMore: false)
        )
        
        // When - 加载第二页
        await sut.loadProducts()
        
        // Then
        XCTAssertEqual(sut.products.count, 20)
    }
}

// MARK: - Mock Service

final class MockProductService: ProductServiceProtocol {
    
    var fetchProductsResult: Result<ProductListResponse, Error>?
    var fetchProductsCalled = false
    var fetchProductsDelay: TimeInterval = 0
    
    func fetchProducts(page: Int, pageSize: Int) async throws -> ProductListResponse {
        fetchProductsCalled = true
        
        if fetchProductsDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(fetchProductsDelay * 1_000_000_000))
        }
        
        return try fetchProductsResult!.get()
    }
    
    func fetchProduct(id: String) async throws -> Product {
        fatalError("Not implemented")
    }
    
    func searchProducts(keyword: String, page: Int) async throws -> ProductListResponse {
        fatalError("Not implemented")
    }
    
    func toggleFavorite(productId: String, isFavorite: Bool) async throws {
        fatalError("Not implemented")
    }
}
```

### Service 测试

```swift
import XCTest
@testable import MiaoJie

final class ProductServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ProductService!
    private var mockClient: MockNetworkClient!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        mockClient = MockNetworkClient()
        sut = ProductService(client: mockClient)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockClient = nil
        try await super.tearDown()
    }
    
    // MARK: - Fetch Products Tests
    
    func testFetchProductsSuccess() async throws {
        // Given
        let expectedResponse = ProductListResponse(
            products: Product.mockList,
            total: 3,
            page: 1,
            pageSize: 20,
            hasMore: false
        )
        mockClient.result = try JSONEncoder().encode(expectedResponse)
        
        // When
        let response = try await sut.fetchProducts(page: 1, pageSize: 20)
        
        // Then
        XCTAssertEqual(response.products.count, 3)
        XCTAssertEqual(response.page, 1)
        XCTAssertFalse(response.hasMore)
    }
    
    func testFetchProductsWithInvalidData() async throws {
        // Given
        mockClient.result = Data()
        
        // Then
        await XCTAssertThrowsAsyncError(
            try await sut.fetchProducts(page: 1, pageSize: 20)
        ) { error in
            XCTAssertTrue(error is NetworkError)
        }
    }
}

// MARK: - Helper Extensions

extension XCTestCase {
    func XCTAssertThrowsAsyncError<T>(
        _ expression: @autoclosure () async throws -> T,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        _ errorHandler: (Error) -> Void
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error but got success", file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
}
```

### Model 测试

```swift
import XCTest
@testable import MiaoJie

final class ProductTests: XCTestCase {
    
    // MARK: - Decoding Tests
    
    func testDecodingFromJSON() throws {
        // Given
        let json = """
        {
            "id": "prod_001",
            "name": "测试商品",
            "price": 99.9,
            "originalPrice": 199.0,
            "imageURL": "https://example.com/image.jpg",
            "tags": ["热销", "新品"]
        }
        """.data(using: .utf8)!
        
        // When
        let product = try JSONDecoder().decode(Product.self, from: json)
        
        // Then
        XCTAssertEqual(product.id, "prod_001")
        XCTAssertEqual(product.name, "测试商品")
        XCTAssertEqual(product.price, 99.9, accuracy: 0.01)
        XCTAssertEqual(product.originalPrice, 199.0, accuracy: 0.01)
        XCTAssertEqual(product.tags.count, 2)
    }
    
    func testDecodingMissingOptionalFields() throws {
        // Given
        let json = """
        {
            "id": "prod_001",
            "name": "测试商品",
            "price": 99.9,
            "originalPrice": 99.9,
            "imageURL": "https://example.com/image.jpg",
            "tags": []
        }
        """.data(using: .utf8)!
        
        // When
        let product = try JSONDecoder().decode(Product.self, from: json)
        
        // Then
        XCTAssertTrue(product.tags.isEmpty)
    }
    
    // MARK: - Computed Properties Tests
    
    func testDiscountPercentage() {
        // Given
        let product = Product(
            id: "1",
            name: "Test",
            price: 80,
            originalPrice: 100,
            imageURL: URL(string: "https://example.com")!,
            tags: []
        )
        
        // Then
        XCTAssertEqual(product.discountPercentage, 20, accuracy: 0.01)
    }
}

// MARK: - Mock Data

extension Product {
    static var mockList: [Product] {
        [
            Product(
                id: "1",
                name: "商品1",
                price: 99.0,
                originalPrice: 199.0,
                imageURL: URL(string: "https://example.com/1.jpg")!,
                tags: ["热销"]
            ),
            Product(
                id: "2",
                name: "商品2",
                price: 88.0,
                originalPrice: 88.0,
                imageURL: URL(string: "https://example.com/2.jpg")!,
                tags: []
            ),
            Product(
                id: "3",
                name: "商品3",
                price: 199.0,
                originalPrice: 299.0,
                imageURL: URL(string: "https://example.com/3.jpg")!,
                tags: ["新品", "限时"]
            )
        ]
    }
}
```

## UI 测试

### 基础 UI 测试

```swift
import XCTest

final class ProductListUITests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDown() async throws {
        app = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests
    
    func testProductListDisplaysProducts() throws {
        // Given
        let collectionView = app.collectionViews["product_list"]
        
        // Then
        XCTAssertTrue(collectionView.waitForExistence(timeout: 5))
        XCTAssertTrue(collectionView.cells.count > 0)
    }
    
    func testTappingProductShowsDetail() throws {
        // Given
        let collectionView = app.collectionViews["product_list"]
        XCTAssertTrue(collectionView.waitForExistence(timeout: 5))
        
        // When
        let firstCell = collectionView.cells.firstMatch
        firstCell.tap()
        
        // Then
        let detailView = app.scrollViews["product_detail"]
        XCTAssertTrue(detailView.waitForExistence(timeout: 3))
    }
    
    func testPullToRefresh() throws {
        // Given
        let collectionView = app.collectionViews["product_list"]
        XCTAssertTrue(collectionView.waitForExistence(timeout: 5))
        
        // When
        collectionView.firstMatch.swipeDown()
        
        // Then - 等待刷新完成
        let refreshIndicator = app.activityIndicators["refresh_indicator"]
        XCTAssertFalse(refreshIndicator.waitForExistence(timeout: 3))
    }
    
    func testEmptyState() throws {
        // Given - 启动时模拟空数据
        app.launchArguments = ["--uitesting", "--empty"]
        app.launch()
        
        // Then
        let emptyLabel = app.staticTexts["empty_state"]
        XCTAssertTrue(emptyLabel.waitForExistence(timeout: 5))
        XCTAssertEqual(emptyLabel.label, "暂无商品")
    }
}

// MARK: - Login Flow Test

final class LoginFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
    }
    
    func testLoginSuccess() throws {
        app.launch()
        
        // Given
        let emailField = app.textFields["email"]
        let passwordField = app.secureTextFields["password"]
        let loginButton = app.buttons["login"]
        
        // When
        emailField.tap()
        emailField.typeText("test@example.com")
        
        passwordField.tap()
        passwordField.typeText("password123")
        
        loginButton.tap()
        
        // Then
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }
    
    func testLoginWithInvalidCredentials() throws {
        app.launch()
        
        // Given
        let emailField = app.textFields["email"]
        let passwordField = app.secureTextFields["password"]
        let loginButton = app.buttons["login"]
        
        // When
        emailField.tap()
        emailField.typeText("invalid")
        
        passwordField.tap()
        passwordField.typeText("invalid")
        
        loginButton.tap()
        
        // Then
        let errorAlert = app.alerts["错误"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 3))
    }
}
```

## 性能测试

```swift
final class ProductDecodingPerformanceTests: XCTestCase {
    
    func testDecodingPerformance() {
        // Given
        let jsonData = generateLargeProductListJSON(count: 1000)
        
        // Then
        measure {
            for _ in 0..<10 {
                _ = try? JSONDecoder().decode(ProductListResponse.self, from: jsonData)
            }
        }
    }
    
    func testDecodingMetrics() throws {
        // Given
        let jsonData = generateLargeProductListJSON(count: 1000)
        
        // Then
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: options) {
            _ = try? JSONDecoder().decode(ProductListResponse.self, from: jsonData)
        }
    }
    
    private func generateLargeProductListJSON(count: Int) -> Data {
        var products: [[String: Any]] = []
        
        for i in 0..<count {
            products.append([
                "id": "prod_\(i)",
                "name": "商品 \(i)",
                "price": Double.random(in: 10...1000),
                "originalPrice": Double.random(in: 100...2000),
                "imageURL": "https://example.com/\(i).jpg",
                "tags": ["标签"]
            ])
        }
        
        let response: [String: Any] = [
            "products": products,
            "total": count,
            "page": 1,
            "pageSize": count,
            "hasMore": false
        ]
        
        return try! JSONSerialization.data(withJSONObject: response)
    }
}
```

## 测试配置

### App Delegate 配置

```swift
// AppDelegate.swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // UI Testing 配置
    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        // 禁用动画
        UIView.setAnimationsEnabled(false)
        
        // 模拟空数据
        if ProcessInfo.processInfo.arguments.contains("--empty") {
            MockDataService.isEmpty = true
        }
    }
    
    return true
}
```

## 边界规则

### ✅ Always do
- 每个测试独立运行
- 使用有意义的测试名称
- 测试失败时提供清晰的错误信息
- Mock 外部依赖

### ⚠️ Ask first
- 复杂的异步测试
- 涉及真实网络的测试

### 🚫 Never do
- 测试之间共享状态
- 在测试中 sleep
- 忽略失败的测试
- 测试私有方法
