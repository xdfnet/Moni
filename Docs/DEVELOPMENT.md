# Moni 项目开发指南

## 开发环境设置

### 系统要求

- **操作系统**：macOS 15.0 或更高版本
- **开发工具**：Xcode 15.0 或更高版本
- **编程语言**：Swift 5.0
- **目标平台**：macOS 15.0+

### 环境配置

1. 安装 Xcode 15.0+
2. 安装 Swift 5.0 工具链
3. 配置开发者账号（用于代码签名）
4. 安装必要的命令行工具

## 项目结构

### 目录组织

```text
Moni/
├── Moni/                    # 主要源代码
│   ├── App.swift           # 应用入口点
│   ├── MenuBarController.swift  # 菜单栏控制器
│   ├── BaseMonitor.swift   # 基础监控类
│   ├── MonitorLatency.swift    # 延迟监控实现
│   ├── MonitorNetwork.swift    # 网络监控实现
│   ├── ServiceManager.swift    # 服务端点管理
│   ├── ConfigurationManager.swift # 配置管理
│   ├── SharedTypes.swift   # 共享类型定义
│   ├── Utilities.swift     # 工具函数库
│   └── Assets.xcassets/    # 应用资源
├── Scripts/                 # 构建和完成
│   └── code_quality_check.sh # 代码质量检查
├── Docs/                    # 项目文档
└── Makefile                 # 构建自动化脚本
```

### 文件命名规范

- **Swift 文件**：使用 PascalCase（如 `MenuBarController.swift`）
- **协议文件**：以 `Protocol` 结尾（如 `MonitorProtocol.swift`）
- **扩展文件**：以 `+` 开头（如 `+Extensions.swift`）
- **测试文件**：以 `Tests` 结尾（如 `MonitorLatencyTests.swift`）

## 代码规范

### 注释规范

遵循 `Docs/COMMENT_STANDARDS.md` 中定义的统一注释标准：

#### 文件头注释

```swift
//
// 文件名.swift
// Moni
//
// 文件描述
// 创建者：开发者姓名
// 创建时间：YYYY-MM-DD
// 最后修改：YYYY-MM-DD
//
```

#### MARK 注释

```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Delegate Methods
```

#### 文档注释

```swift
/// 监控器代理协议
/// 用于接收监控结果和错误通知
protocol MonitorDelegate: AnyObject {
    /// 监控成功回调
    /// - Parameters:
    ///   - monitor: 监控器实例
    ///   - result: 监控结果
    func monitor(_ monitor: BaseMonitor, didSucceedWithResult result: MonitorResult)
}
```

### 命名规范

- **类名**：使用 PascalCase（如 `MonitorLatency`）
- **协议名**：使用 PascalCase，以 `Protocol` 结尾（如 `MonitorProtocol`）
- **方法名**：使用 camelCase（如 `startMonitoring`）
- **属性名**：使用 camelCase（如 `isMonitoring`）
- **常量名**：使用 camelCase（如 `maxRetryCount`）
- **枚举值**：使用 camelCase（如 `case serviceLatency`）

### 代码组织

- 每个文件不超过 500 行
- 相关功能组织在同一个文件中
- 使用扩展分离不同功能
- 遵循单一职责原则

## 新增功能开发指南

### 1. 添加新的监控器

#### 步骤 1：创建监控器类

```swift
import Foundation

/// 新监控器类
/// 继承 BaseMonitor 获得通用功能
final class MonitorNew: BaseMonitor {
    
    // MARK: - Properties
    
    /// 监控结果
    private var result: NewMonitorResult?
    
    // MARK: - Override Methods
    
    override func performMonitoring() {
        // 实现具体的监控逻辑
        // 调用 delegate 方法通知结果
    }
    
    override func cleanup() {
        // 清理资源
        super.cleanup()
    }
}
```

#### 步骤 2：定义代理协议

```swift
/// 新监控器代理协议
protocol MonitorNewDelegate: AnyObject {
    func monitor(_ monitor: MonitorNew, didUpdateResult result: NewMonitorResult)
    func monitor(_ monitor: MonitorNew, didFailWithError error: MonitorError)
}
```

#### 步骤 3：在 MenuBarController 中集成

```swift
extension MenuBarController: 
    MonitorNewDelegate {
    
    func monitor(_ monitor: MonitorNew, 
            didUpdateResult result: NewMonitorResult) {
        // 处理监控结果
        updateDisplay(with: result)
    }
    
    func monitor(_ monitor: MonitorNew, didFailWithError error: MonitorError) {
        // 处理错误
        handleError(error)
    }
}
```

### 2. 添加新的配置项

#### 步骤 1：在 ConfigurationManager 中定义

```swift
extension ConfigKeys {
    static let newFeature = "newFeature"
    static let newFeatureEnabled = "newFeatureEnabled"
}

extension ConfigurationManager {
    
    /// 新功能开关
    var isNewFeatureEnabled: Bool {
        get { userDefaults.bool(forKey: ConfigKeys.newFeatureEnabled) }
        set { 
            userDefaults.set(newValue, forKey: ConfigKeys.newFeatureEnabled)
            notifyConfigurationChanged()
        }
    }
    
    /// 新功能配置
    var newFeatureConfig: NewFeatureConfig? {
        get {
            guard let data = userDefaults.data(forKey: ConfigKeys.newFeature) 
else { return nil }
            return try? JSONDecoder().decode(NewFeatureConfig.self, from: data)
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: ConfigKeys.newFeature)
            }
            notifyConfigurationChanged()
        }
    }
}
```

#### 步骤 2：添加配置验证

```swift
extension ConfigurationManager {
    
    /// 验证新功能配置
    func validateNewFeatureConfig(_ config: NewFeatureConfig) -> Bool {
        // 实现配置验证逻辑
        return config.isValid
    }
}
```

### 3. 添加新的工具函数

#### 步骤 1：在 Utilities 中定义

```swift
extension Utilities {
    
    /// 新工具函数
    /// - Parameter input: 输入参数
    /// - Returns: 处理结果
    static func newUtilityFunction(input: String) -> String {
        // 实现工具函数逻辑
        return processedInput
    }
    
    /// 安全的集合访问
    /// - Parameters:
    ///   - array: 目标数组
    ///   - index: 索引位置
    /// - Returns: 安全访问的结果
    static func safeArrayAccess<T>(_ array: [T], at index: Int) -> T? {
        guard index >= 0 && index < array.count else { return nil }
        return array[index]
    }
}
```

## 错误处理指南

### 1. 定义错误类型

```swift
extension MonitorError {
    
    /// 新功能相关错误
    case newFeatureError(String)
    case invalidNewFeatureConfig
    case newFeatureTimeout
}
```

### 2. 实现状态管理

```swift
extension MonitorNew {
    
    private func handleError(_ error: MonitorError) {
        switch error {
        case .newFeatureTimeout:
            // 实现连接状态管理
updateConnectionStatus()
        case .invalidNewFeatureConfig:
            // 重置到默认配置
            resetToDefaultConfig()
        default:
            // 通用错误处理
            delegate?.monitor(self, didFailWithError: error)
        }
    }
    
    private func updateConnectionStatus() {
        // 实现连接状态更新
        connectionStatus = .disconnected
        updateDisplay()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { 
    [weak self] in
            self?.performMonitoring()
        }
    }
}
```

## 测试指南

### 1. 单元测试

```swift
import XCTest
@testable import Moni

final class MonitorNewTests: XCTestCase {
    
    var monitor: MonitorNew!
    var mockDelegate: MockMonitorNewDelegate!
    
    override func setUp() {
        super.setUp()
        monitor = MonitorNew()
        mockDelegate = MockMonitorNewDelegate()
        monitor.delegate = mockDelegate
    }
    
    override func tearDown() {
        monitor = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testMonitoringSuccess() {
        // 测试监控成功场景
        monitor.startMonitoring()
        
        // 验证结果
        XCTAssertTrue(mockDelegate.didReceiveResult)
        XCTAssertNil(mockDelegate.lastError)
    }
    
    func testMonitoringFailure() {
        // 测试监控失败场景
        monitor.simulateError(.newFeatureError("Test error"))
        
        // 验证错误处理
        XCTAssertFalse(mockDelegate.didReceiveResult)
        XCTAssertNotNil(mockDelegate.lastError)
    }
}
```

### 2. 性能测试

```swift
func testMonitoringPerformance() {
    measure {
        // 执行监控操作
        monitor.performMonitoring()
    }
}
```

## 构建和部署

### 1. 使用 Makefile

```bash
# 完整构建（包含版本号递增）
make build

# 固定版本构建
make build-fixed

# 清理构建文件
make clean

# 代码质量检查
make quality-check
```

### 2. 版本管理

- 使用 `CFBundleShortVersionString` 作为营销版本
- 使用 `CFBundleVersion` 作为构建版本
- 每次发布时递增版本号

### 3. 代码签名

- 配置开发者证书
- 设置正确的 Bundle Identifier
- 配置 Entitlements 文件

## 调试技巧

### 1. 日志输出

```swift
// 使用 Utilities 中的调试工具
Utilities.debugPrint("监控器状态：\(monitorState)")
Utilities.printPerformanceStats("监控操作耗时")
```

### 2. 性能分析

```swift
// 测量函数执行时间
let executionTime = Utilities.measureExecutionTime {
    performComplexOperation()
}
print("操作耗时：\(executionTime) 秒")
```

### 3. 内存泄漏检测

- 使用 Xcode 的 Memory Graph Debugger
- 检查循环引用
- 验证 deinit 方法被正确调用

## 代码审查清单

### 功能完整性

- [ ] 新功能是否完整实现
- [ ] 是否包含必要的错误处理
- [ ] 是否支持配置管理
- [ ] 是否包含适当的日志记录

### 代码质量

- [ ] 是否遵循命名规范
- [ ] 是否包含完整的注释
- [ ] 是否通过代码质量检查
- [ ] 是否包含单元测试

### 性能考虑

- [ ] 是否避免不必要的内存分配
- [ ] 是否使用适当的队列
- [ ] 是否包含超时处理
- [ ] 是否支持取消操作

### 用户体验

- [ ] 是否提供用户友好的错误信息
- [ ] 是否支持状态指示
- [ ] 是否包含进度反馈
- [ ] 是否支持配置持久化

## 常见问题解决

### 1. 编译错误

- 检查 Swift 版本兼容性
- 验证导入语句
- 检查类型推断问题

### 2. 运行时错误

- 使用 Instruments 进行性能分析
- 检查内存管理
- 验证线程安全

### 3. 构建问题

- 清理构建文件
- 检查项目配置
- 验证代码签名设置

---

开发指南 - 最后更新：2025年8月
