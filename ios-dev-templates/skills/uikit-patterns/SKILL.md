---
name: uikit-patterns
description: UIKit 开发模式和最佳实践。用于创建 UIViewController、UITableView、UICollectionView 等 UIKit 组件。触发条件：(1) 创建新的 ViewController，(2) 实现列表界面，(3) 自定义 UI 组件，(4) 处理布局和约束，(5) 实现动画效果。
---

# UIKit 开发模式

你是 UIKit 开发专家。你熟悉 UIKit 的各种组件、Auto Layout、以及 MVVM 架构的最佳实践。

## 架构模式

### MVVM + Coordinator

```swift
// MARK: - ViewModel

@MainActor
final class ProductListViewModel {
    
    // MARK: - Properties
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    
    private let productService: ProductServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Callback 方式 (可选)
    var onProductsUpdated: (() -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init(productService: ProductServiceProtocol) {
        self.productService = productService
    }
    
    // MARK: - Public Methods
    
    func loadProducts() {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let response = try await productService.fetchProducts(page: 1, pageSize: 20)
                products = response.products
                onProductsUpdated?()
            } catch {
                self.error = error.localizedDescription
                onError?(error.localizedDescription)
            }
            isLoading = false
        }
    }
    
    func product(at index: Int) -> Product? {
        guard products.indices.contains(index) else { return nil }
        return products[index]
    }
    
    var numberOfProducts: Int {
        products.count
    }
}

// MARK: - ViewController

final class ProductListViewController: UIViewController {
    
    // MARK: - Properties
    
    private let viewModel: ProductListViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemBackground
        cv.register(MJProductCell.self, forCellWithReuseIdentifier: MJProductCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    // MARK: - Initialization
    
    init(viewModel: ProductListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadProducts()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "商品列表"
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func bindViewModel() {
        // 使用 Combine
        viewModel.$products
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "错误",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ProductListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfProducts
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MJProductCell.identifier,
            for: indexPath
        ) as? MJProductCell else {
            return UICollectionViewCell()
        }
        
        if let product = viewModel.product(at: indexPath.item) {
            cell.configure(with: product)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ProductListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let product = viewModel.product(at: indexPath.item) else { return }
        
        // 使用 Coordinator 或直接跳转
        let detailVC = ProductDetailViewController(product: product)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ProductListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = (collectionView.bounds.width - 12) / 2
        return CGSize(width: width, height: width * 1.3)
    }
}
```

## 自定义 Cell

```swift
import UIKit

final class MJProductCell: UICollectionViewCell {
    
    // MARK: - Static
    
    static let identifier = "MJProductCell"
    
    // MARK: - UI Components
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .systemGray5
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .systemRed
        return label
    }()
    
    private let originalPriceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(originalPriceLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            
            originalPriceLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            originalPriceLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 4),
            originalPriceLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with product: Product) {
        nameLabel.text = product.name
        priceLabel.text = String(format: "¥%.2f", product.price)
        
        if product.originalPrice > product.price {
            let attributeString = NSMutableAttributedString(string: String(format: "¥%.0f", product.originalPrice))
            attributeString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: attributeString.length))
            originalPriceLabel.attributedText = attributeString
            originalPriceLabel.isHidden = false
        } else {
            originalPriceLabel.isHidden = true
        }
        
        // 图片加载 (使用 SDWebImage 或 Kingfisher)
        // imageView.sd_setImage(with: product.imageURL)
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        nameLabel.text = nil
        priceLabel.text = nil
        originalPriceLabel.text = nil
    }
}
```

## Coordinator 模式

```swift
// MARK: - Coordinator Protocol

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

// MARK: - App Coordinator

final class AppCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    private let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
        self.navigationController = UINavigationController()
    }
    
    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        // 检查登录状态
        if AuthService.shared.isLoggedIn {
            showMainTabBar()
        } else {
            showLogin()
        }
    }
    
    private func showLogin() {
        let loginCoordinator = LoginCoordinator(navigationController: navigationController)
        loginCoordinator.delegate = self
        childCoordinators.append(loginCoordinator)
        loginCoordinator.start()
    }
    
    private func showMainTabBar() {
        let tabBarController = UITabBarController()
        
        // 首页
        let homeNav = UINavigationController()
        let homeCoordinator = HomeCoordinator(navigationController: homeNav)
        homeCoordinator.start()
        
        // 购物车
        let cartNav = UINavigationController()
        let cartCoordinator = CartCoordinator(navigationController: cartNav)
        cartCoordinator.start()
        
        // 我的
        let profileNav = UINavigationController()
        let profileCoordinator = ProfileCoordinator(navigationController: profileNav)
        profileCoordinator.start()
        
        tabBarController.viewControllers = [homeNav, cartNav, profileNav]
        
        navigationController.setViewControllers([tabBarController], animated: false)
    }
}

// MARK: - Login Coordinator

final class LoginCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    
    weak var delegate: LoginCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewModel = LoginViewModel(authService: AuthService.shared)
        let loginVC = LoginViewController(viewModel: viewModel)
        loginVC.delegate = self
        navigationController.setViewControllers([loginVC], animated: false)
    }
    
    private func showRegister() {
        let viewModel = RegisterViewModel(authService: AuthService.shared)
        let registerVC = RegisterViewController(viewModel: viewModel)
        navigationController.pushViewController(registerVC, animated: true)
    }
}

// MARK: - Login Coordinator Delegate

protocol LoginCoordinatorDelegate: AnyObject {
    func loginCoordinatorDidFinish(_ coordinator: LoginCoordinator)
}

extension AppCoordinator: LoginCoordinatorDelegate {
    func loginCoordinatorDidFinish(_ coordinator: LoginCoordinator) {
        childCoordinators.removeAll { $0 === coordinator }
        showMainTabBar()
    }
}
```

## 代码组织规范

### 文件结构

```swift
// MARK: - 类/文件结构模板

final class ViewController: UIViewController {
    
    // MARK: - Type Properties
    // 静态属性
    
    // MARK: - Instance Properties
    // 实例属性
    
    // UI Components
    // UI 组件 (lazy var)
    
    // MARK: - Initialization
    // 初始化方法
    
    // MARK: - Lifecycle
    // 生命周期方法
    
    // MARK: - Setup
    // UI 设置方法
    
    // MARK: - Public Methods
    // 公共方法
    
    // MARK: - Private Methods
    // 私有方法
    
    // MARK: - Actions
    // @objc 方法 / IBAction
}

// MARK: - Protocol Conformance
// 协议实现
```

## 边界规则

### ✅ Always do
- 使用 `final` 修饰不需要继承的类
- UI 更新确保在主线程
- Cell 复用时重置状态
- 使用 Auto Layout

### ⚠️ Ask first
- 大量数据的列表实现
- 复杂的手势交互
- 自定义转场动画

### 🚫 Never do
- 强引用 ViewController
- 在 `viewDidLoad` 之前访问 UI
- 忘记设置 `translatesAutoresizingMaskIntoConstraints = false`
- 在 Cell 中直接处理业务逻辑
