---
name: core-data
description: Core Data 持久化专家。用于设计数据模型、实现 CRUD 操作、处理数据迁移和性能优化。触发条件：(1) 创建 Core Data 模型，(2) 实现数据持久化，(3) 数据迁移，(4) 复杂查询，(5) 性能优化。
---

# Core Data 持久化

你是 Core Data 持久化专家。你熟悉 Core Data 栈的搭建、并发模型、数据迁移和性能优化。

## 架构设计

```
Persistence/
├── CoreDataStack.swift          # Core Data 栈
├── PersistentContainer+.swift   # 容器扩展
│
├── Models/
│   ├── Model.xcdatamodeld       # 数据模型文件
│   └── Entities/
│       ├── Product+CoreDataClass.swift
│       ├── Product+CoreDataProperties.swift
│       └── Product+Extensions.swift
│
├── Repositories/
│   ├── ProductRepository.swift
│   └── OrderRepository.swift
│
└── Migrations/
    └── MigrationManager.swift
```

## Core Data 栈

```swift
import CoreData

// MARK: - Core Data Stack

final class CoreDataStack {
    
    // MARK: - Singleton
    
    static let shared = CoreDataStack()
    
    // MARK: - Properties
    
    private let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        container.newBackgroundContext()
    }
    
    // MARK: - Initialization
    
    private init() {
        container = NSPersistentContainer(name: "MiaoJie")
        
        // 配置
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data stack failed: \(error), \(error.userInfo)")
            }
        }
        
        // 性能优化
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Public Methods
    
    func save() {
        let context = container.viewContext
        
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            // 记录错误但不崩溃
            print("Core Data save error: \(error)")
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async rethrows -> T {
        try await container.performBackgroundTask(block)
    }
}

// MARK: - Preview Support

extension CoreDataStack {
    static var preview: CoreDataStack = {
        let stack = CoreDataStack()
        stack.container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        return stack
    }()
}
```

## Entity 定义

### 自动生成后扩展

```swift
// Product+CoreDataProperties.swift (Xcode 自动生成)
import CoreData

extension Product {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Product> {
        return NSFetchRequest<Product>(entityName: "Product")
    }
    
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var price: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var imageData: Data?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var order: Order?
}

extension Product: Identifiable {}
```

### 手动扩展

```swift
// Product+Extensions.swift
import CoreData

extension Product {
    
    // MARK: - Computed Properties
    
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Factory Methods
    
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        id: String,
        name: String,
        price: Double
    ) -> Product {
        let product = Product(context: context)
        product.id = id
        product.name = name
        product.price = price
        product.createdAt = Date()
        product.updatedAt = Date()
        product.isFavorite = false
        return product
    }
    
    // MARK: - Fetch Requests
    
    static func fetchById(_ id: String) -> NSFetchRequest<Product> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return request
    }
    
    static func fetchFavorites() -> NSFetchRequest<Product> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.updatedAt, ascending: false)]
        return request
    }
    
    static func fetchRecent(limit: Int = 20) -> NSFetchRequest<Product> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)]
        request.fetchLimit = limit
        return request
    }
    
    // MARK: - Batch Operations
    
    static func deleteAll(in context: NSManagedObjectContext) throws {
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest())
        try context.execute(request)
    }
}
```

## Repository 模式

```swift
import CoreData

// MARK: - Protocol

protocol ProductRepositoryProtocol {
    func fetchAll() async throws -> [Product]
    func fetch(byId id: String) async throws -> Product?
    func fetchFavorites() async throws -> [Product]
    func save(_ product: Product) async throws
    func delete(_ product: Product) async throws
    func toggleFavorite(_ product: Product) async throws
}

// MARK: - Implementation

final class ProductRepository: ProductRepositoryProtocol {
    
    // MARK: - Properties
    
    private let stack: CoreDataStack
    
    // MARK: - Initialization
    
    init(stack: CoreDataStack = .shared) {
        self.stack = stack
    }
    
    // MARK: - Public Methods
    
    func fetchAll() async throws -> [Product] {
        try await stack.performBackgroundTask { context in
            let request = Product.fetchRecent()
            return try context.fetch(request)
        }
    }
    
    func fetch(byId id: String) async throws -> Product? {
        try await stack.performBackgroundTask { context in
            let request = Product.fetchById(id)
            return try context.fetch(request).first
        }
    }
    
    func fetchFavorites() async throws -> [Product] {
        try await stack.performBackgroundTask { context in
            let request = Product.fetchFavorites()
            return try context.fetch(request)
        }
    }
    
    func save(_ product: Product) async throws {
        try await stack.performBackgroundTask { context in
            // 如果是新对象，需要在正确的 context 创建
            if product.managedObjectContext == nil {
                let newProduct = Product(context: context)
                newProduct.id = product.id
                newProduct.name = product.name
                newProduct.price = product.price
                newProduct.updatedAt = Date()
            } else {
                product.updatedAt = Date()
            }
            
            try context.save()
        }
    }
    
    func delete(_ product: Product) async throws {
        try await stack.performBackgroundTask { context in
            // 需要在同一个 context 中操作
            guard let object = try context.existingObject(with: product.objectID) as? Product else {
                return
            }
            context.delete(object)
            try context.save()
        }
    }
    
    func toggleFavorite(_ product: Product) async throws {
        try await stack.performBackgroundTask { context in
            guard let object = try context.existingObject(with: product.objectID) as? Product else {
                return
            }
            object.isFavorite.toggle()
            object.updatedAt = Date()
            try context.save()
        }
    }
}
```

## 与 SwiftUI 集成

```swift
import SwiftUI
import CoreData

// MARK: - Fetch Request Extension

extension FetchRequest {
    static func products(sortBy: SortDescriptor<Product> = SortDescriptor(\.createdAt, order: .reverse)) -> FetchRequest<Product> {
        FetchRequest<Product>(
            sortDescriptors: [NSSortDescriptor(sortBy)],
            animation: .default
        )
    }
    
    static func favoriteProducts() -> FetchRequest<Product> {
        FetchRequest<Product>(
            fetchRequest: Product.fetchFavorites(),
            animation: .default
        )
    }
}

// MARK: - View

struct FavoriteProductsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var products: FetchedResults<Product>
    
    init() {
        _products = FetchRequest<Product>(
            fetchRequest: Product.fetchFavorites(),
            animation: .default
        )
    }
    
    var body: some View {
        List {
            ForEach(products) { product in
                ProductRowView(product: product)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            removeFavorite(product)
                        } label: {
                            Label("移除", systemImage: "heart.slash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .navigationTitle("收藏")
    }
    
    private func removeFavorite(_ product: Product) {
        product.isFavorite = false
        product.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to remove favorite: \(error)")
        }
    }
}
```

## 性能优化

### 批量操作

```swift
// ✅ 正确 - 批量插入
func batchInsert(products: [ProductDTO]) async throws {
    try await stack.performBackgroundTask { context in
        for dto in products {
            Product.create(
                in: context,
                id: dto.id,
                name: dto.name,
                price: dto.price
            )
        }
        try context.save()
    }
}

// ✅ 正确 - 批量删除
func batchDelete(ids: [String]) async throws {
    try await stack.performBackgroundTask { context in
        let request = NSBatchDeleteRequest(
            fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "Product")
        )
        request.predicate = NSPredicate(format: "id IN %@", ids)
        try context.execute(request)
    }
}
```

### Faulting & Prefetching

```swift
// 预加载关系数据
func fetchOrdersWithProducts() async throws -> [Order] {
    try await stack.performBackgroundTask { context in
        let request = Order.fetchRequest() as! NSFetchRequest<Order>
        
        // 预加载关系
        request.relationshipKeyPathsForPrefetching = ["products"]
        
        return try context.fetch(request)
    }
}
```

### 内存管理

```swift
// 及时释放不需要的对象
func processLargeDataset() async throws {
    try await stack.performBackgroundTask { context in
        let request = Product.fetchRequest()
        request.batchSize = 50  // 分批处理
        
        var results: [Result] = []
        
        try context.performAndWait {
            let products = try context.fetch(request)
            
            for product in products {
                // 处理数据
                let result = process(product)
                results.append(result)
                
                // 定期刷新上下文释放内存
                if results.count % 100 == 0 {
                    context.reset()
                }
            }
        }
        
        return results
    }
}
```

## 边界规则

### ✅ Always do
- 使用 backgroundContext 处理大量数据
- 批量操作时设置 batchSize
- 及时保存上下文
- 处理并发访问

### ⚠️ Ask first
- 修改数据模型
- 添加新的 Entity
- 实现数据迁移

### 🚫 Never do
- 在主线程执行大量数据操作
- 跨 Context 共享 NSManagedObject
- 忽略 Core Data 错误
- 长时间持有大量对象
