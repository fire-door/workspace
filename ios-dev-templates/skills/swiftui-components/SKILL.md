---
name: swiftui-components
description: SwiftUI 组件开发专家。用于创建可复用的 SwiftUI 视图、修饰符和动画。触发条件：(1) 创建新的 SwiftUI 视图，(2) 设计自定义组件，(3) 实现复杂的 UI 交互，(4) 添加视图修饰符，(5) 实现动画效果。
---

# SwiftUI 组件开发

你是 SwiftUI 组件开发专家。你熟悉 SwiftUI 的最佳实践、性能优化技巧，以及如何创建可复用、可测试的视图组件。

## 核心原则

1. **视图拆分** — 单一职责，每个视图只做一件事
2. **状态驱动** — 使用 `@State`、`@Binding`、`@Observable`
3. **可预览** — 所有视图都应该有 `#Preview`
4. **可访问性** — 支持 Dynamic Type 和 VoiceOver
5. **性能优先** — 合理使用 `@StateObject`、`@ObservedObject`、`@EnvironmentObject`

## 视图模板

### 基础列表视图

```swift
import SwiftUI

struct MJProductListView: View {
    @StateObject private var viewModel: MJProductListViewModel
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("商品列表")
                .task {
                    await viewModel.loadProducts()
                }
                .refreshable {
                    await viewModel.refresh()
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            idleView
        case .loading:
            loadingView
        case .loaded:
            loadedView
        case .empty:
            emptyView
        case .error(let message):
            errorView(message)
        }
    }
    
    // MARK: - Subviews
    
    private var idleView: some View {
        ContentUnavailableView(
            "准备就绪",
            systemImage: "checkmark.circle"
        )
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("加载中...")
                .foregroundStyle(.secondary)
        }
    }
    
    private var loadedView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(viewModel.products) { product in
                    MJProductCardView(product: product)
                        .onTapGesture {
                            viewModel.selectProduct(product)
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "暂无商品",
            systemImage: "box",
            description: Text("换个关键词试试")
        )
        .onTapGesture {
            viewModel.retry()
        }
    }
    
    private func errorView(_ message: String) -> some View {
        ContentUnavailableView(
            "加载失败",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .onTapGesture {
            viewModel.retry()
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }
}

// MARK: - Preview

#Preview("商品列表 - 加载完成") {
    MJProductListView(viewModel: .init(products: .mockList))
}

#Preview("商品列表 - 空状态") {
    MJProductListView(viewModel: .init(state: .empty))
}

#Preview("商品列表 - 错误") {
    MJProductListView(viewModel: .init(state: .error("网络错误")))
}
```

### 卡片组件

```swift
import SwiftUI

struct MJProductCardView: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 商品图片
            AsyncImage(url: product.imageURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(.gray.opacity(0.1))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(.gray.opacity(0.1))
                        .overlay(Image(systemName: "photo"))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // 商品信息
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                HStack {
                    Text(product.price, format: .currency(code: "CNY"))
                        .font(.headline)
                        .foregroundStyle(.red)
                    
                    Spacer()
                    
                    if product.originalPrice > product.price {
                        Text(product.originalPrice, format: .currency(code: "CNY"))
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                }
                
                // 标签
                if !product.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(product.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.1))
                                .foregroundStyle(.red)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
            ForEach(Product.mockList) { product in
                MJProductCardView(product: product)
            }
        }
        .padding()
    }
}
```

### 加载按钮

```swift
import SwiftUI

struct MJLoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isLoading ? Color.gray : Color.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        MJLoadingButton(title: "提交订单", isLoading: false) {}
        MJLoadingButton(title: "提交中...", isLoading: true) {}
    }
    .padding()
}
```

## 自定义修饰符

### 圆角卡片修饰符

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// 使用
Text("内容")
    .cardStyle()
```

### 加载遮罩修饰符

```swift
struct LoadingOverlay: ViewModifier {
    let isLoading: Bool
    let message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            
            if isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    if let message = message {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
    }
}

extension View {
    func loadingOverlay(_ isLoading: Bool, message: String? = nil) -> some View {
        modifier(LoadingOverlay(isLoading: isLoading, message: message))
    }
}

// 使用
NavigationView { ... }
    .loadingOverlay(isLoading, message: "加载中...")
```

## 动画技巧

### Hero 转场动画

```swift
struct ProductListView: View {
    @Namespace private var namespace
    @State private var selectedProduct: Product?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                    ForEach(products) { product in
                        ProductCard(product: product)
                            .matchedGeometryEffect(
                                id: product.id,
                                in: namespace,
                                isSource: selectedProduct == nil
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedProduct = product
                                }
                            }
                    }
                }
            }
            .navigationDestination(item: $selectedProduct) { product in
                ProductDetailView(product: product)
                    .matchedGeometryEffect(
                        id: product.id,
                        in: namespace,
                        isSource: selectedProduct != nil
                    )
            }
        }
    }
}
```

### 数字滚动动画

```swift
struct AnimatedNumber: View {
    let value: Int
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .contentTransition(.numericText())
            .onChange(of: value) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    displayValue = newValue
                }
            }
    }
}
```

## 性能优化

### 避免不必要的重绘

```swift
// ✅ 正确 - 将静态内容提取
struct ProductCard: View {
    let product: Product
    
    var body: some View {
        VStack {
            ProductImageView(url: product.imageURL)  // 独立视图
            ProductInfoView(product: product)        // 独立视图
        }
    }
}

// ❌ 错误 - 所有内容在一个大闭包里
struct ProductCard: View {
    var body: some View {
        VStack {
            // 大量代码...
        }
    }
}
```

### 使用 Equatable

```swift
struct ProductCard: View, Equatable {
    let product: Product
    
    static func == (lhs: ProductCard, rhs: ProductCard) -> Bool {
        lhs.product.id == rhs.product.id &&
        lhs.product.name == rhs.product.name &&
        lhs.product.price == rhs.product.price
    }
    
    var body: some View {
        // 只有 product 相关字段变化时才会重绘
    }
}
```

## 边界规则

### ✅ Always do
- 每个视图都有 `#Preview`
- 大视图拆分成小组件
- 使用 `@ViewBuilder` 组织代码
- 复杂动画使用 `withAnimation`

### ⚠️ Ask first
- 大量数据的列表渲染
- 复杂的手势交互
- 自定义 Layout

### 🚫 Never do
- 在视图内进行网络请求
- 过深的视图嵌套
- 忽略可访问性
