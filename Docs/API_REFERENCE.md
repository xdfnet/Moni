# Moni API 参考文档

## 概述

本文档提供了 Moni 项目中所有公共 API 的详细说明，包括类、协议、方法和属性的完整参考。

## 核心类

### App

应用的主入口点，负责应用生命周期管理。

```swift
@main
struct MoniApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
```

**继承关系**：`App` 协议

**主要职责**：
- 应用启动和初始化
- 生命周期管理
- 菜单栏应用配置

---

### MenuBarController

管理菜单栏界面和用户交互的核心控制器。

```swift
final class MenuBarController: NSObject {
    // 公共属性和方法
}
```

**继承关系**：`NSObject`

**协议遵循**：`MonitorLatencyDelegate`, `MonitorNetworkDelegate`

#### 主要属性

```swift
/// 当前显示模式
var displayMode: DisplayMode { get set }

/// 当前监控间隔
var monitoringInterval: TimeInterval { get set }

/// 最后发生的错误
var lastError: MonitorError? { get set }

/// 应用健康状态
var isHealthy: Bool { get set }
```

#### 主要方法

```swift
/// 启动监控
func startMonitoring()

/// 停止监控
func stopMonitoring()

/// 更新显示内容
func updateCombinedDisplay()

/// 创建状态图标
func createStatusIcon() -> String

/// 创建工具提示
func createTooltip() -> String

/// 显示用户友好的错误信息
func showUserFriendlyError(_ error: MonitorError) -> String
```

#### 代理方法

```swift
// MARK: - MonitorLatencyDelegate
func monitor(_ monitor: MonitorLatency, didUpdateLatency latency: TimeInterval, for endpoint: ServiceEndpoint)

func monitor(_ monitor: MonitorLatency, didFailWithError error: MonitorError, for endpoint: ServiceEndpoint)

// MARK: - MonitorNetworkDelegate
func monitor(_ monitor: MonitorNetwork, didUpdateSpeed speed: Double)

func monitor(_ monitor: MonitorNetwork, didFailWithError error: MonitorError)
```

---

### BaseMonitor

所有监控器的基类，提供通用的监控功能。

```swift
class BaseMonitor: NSObject {
    // 公共属性和方法
}
```

**继承关系**：`NSObject`

**协议遵循**：无

#### 主要属性

```swift
/// 监控队列
let queue: DispatchQueue

/// 监控间隔
var interval: TimeInterval { get set }

/// 是否正在监控
var isMonitoring: Bool { get }

/// 监控锁（线程安全）
private let monitoringLock = NSLock()
```

#### 主要方法

```swift
/// 启动监控
func startMonitoring()

/// 停止监控
func stopMonitoring()

/// 清理资源
func cleanup()

/// 更新监控间隔
func updateInterval(_ newInterval: TimeInterval)

/// 执行监控（子类必须实现）
func performMonitoring()
```

#### 生命周期

```swift
/// 初始化
init(queueLabel: String, interval: TimeInterval)

/// 析构
deinit
```

---

### MonitorLatency

监控 AI 服务网络延迟的具体实现。

```swift
final class MonitorLatency: BaseMonitor {
    // 公共属性和方法
}
```

**继承关系**：`BaseMonitor`

**协议遵循**：无

#### 主要属性

```swift
/// 延迟监控代理
weak var delegate: MonitorLatencyDelegate?

/// 当前连接
private var currentConnection: NWConnection?

/// 是否正在重试
private var isRetrying: Bool = false

/// 当前重试延迟
private var currentRetryDelay: TimeInterval = MonitorConstants.initialRetryDelay
```

#### 主要方法

```swift
/// 执行延迟监控
override func performMonitoring()

/// 处理连接状态变化
private func handleConnectionStateChange(_ state: NWConnection.State)

/// 处理成功连接
private func handleSuccessfulConnection()

/// 处理连接超时
private func handleConnectionTimeout()

/// 处理连接失败
private func handleConnectionFailure(_ error: Error)
```

#### 重试机制

```swift
/// 智能重试（指数退避 + 抖动）
private func handleConnectionFailure(_ error: Error)

/// 记录重试尝试
private func logRetryAttempt(attempt: Int, delay: TimeInterval)

/// 记录最大重试次数达到
private func logMaxRetriesReached()
```

---

### MonitorNetwork

监控系统网络流量的具体实现。

```swift
final class MonitorNetwork: BaseMonitor {
    // 公共属性和方法
}
```

**继承关系**：`BaseMonitor`

**协议遵循**：无

#### 主要属性

```swift
/// 网络监控代理
weak var delegate: MonitorNetworkDelegate?

/// 上次接收的字节数
private var lastReceived: UInt64 = 0

/// 当前接收的字节数
private var currentReceived: UInt64 = 0

/// 网络接口名称
private let interfaceName: String
```

#### 主要方法

```swift
/// 执行网络监控
override func performMonitoring()

/// 重置网络统计
private func resetNetworkStats()

/// 验证网络数据有效性
private func validateNetworkData(_ received: UInt64) -> Bool

/// 计算下载速度
private func calculateDownloadSpeed() -> Double
```

#### 数据验证

```swift
/// 检测网络接口重置
private func detectInterfaceReset(_ current: UInt64) -> Bool

/// 检测不合理的速度值
private func detectUnreasonableSpeed(_ speed: Double) -> Bool

/// 记录网络接口重置
private func logNetworkInterfaceReset()

/// 记录不合理的速度值
private func logUnreasonableSpeed(_ speed: Double)
```

---

### ServiceManager

管理 AI 服务端点的配置和选择。

```swift
final class ServiceManager {
    // 公共属性和方法
}
```

**继承关系**：无

**协议遵循**：无

#### 主要属性

```swift
/// 共享实例
static let shared = ServiceManager()

/// 内置服务端点
private let builtinEndpoints: [ServiceEndpoint]

/// 自定义端点
private var customEndpoints: [ServiceEndpoint] = []
```

#### 主要方法

```swift
/// 获取所有可用端点
func getAllEndpoints() -> [ServiceEndpoint]

/// 添加自定义端点
func addCustomEndpoint(_ endpoint: ServiceEndpoint)

/// 移除自定义端点
func removeCustomEndpoint(_ endpoint: ServiceEndpoint)

/// 验证端点有效性
func validateEndpoint(_ endpoint: ServiceEndpoint) -> Bool
```

---

### ConfigurationManager

统一管理应用配置的中央管理器。

```swift
final class ConfigurationManager {
    // 公共属性和方法
}
```

**继承关系**：无

**协议遵循**：无

#### 主要属性

```swift
/// 共享实例
static let shared = ConfigurationManager()

/// 用户默认设置
private let userDefaults = UserDefaults.standard

/// 配置操作队列
private let configQueue = DispatchQueue(label: "com.moni.config", qos: .userInitiated)
```

#### 主要方法

```swift
/// 获取显示模式
var displayMode: DisplayMode { get set }

/// 获取监控间隔
var monitoringInterval: TimeInterval { get set }

/// 获取选中的服务端点
var selectedService: ServiceEndpoint? { get set }

/// 获取通知设置
var notificationsEnabled: Bool { get set }

/// 获取重试设置
var maxRetries: Int { get set }

/// 获取超时设置
var connectionTimeout: TimeInterval { get set }
```

#### 配置管理

```swift
/// 导入配置
func importConfiguration(from data: Data) throws

/// 导出配置
func exportConfiguration() throws -> Data

/// 重置为默认配置
func resetToDefaults()

/// 验证配置有效性
func validateConfiguration() -> Bool

/// 通知配置变更
func notifyConfigurationChanged()
```

---

### Utilities

提供通用工具函数的静态工具类。

```swift
struct Utilities {
    // 静态方法
}
```

**继承关系**：无

**协议遵循**：无

#### 安全转换工具

```swift
/// 安全整数转换
static func safeInt(_ value: Any?) -> Int?

/// 安全浮点数转换
static func safeDouble(_ value: Any?) -> Double?

/// 安全字符串转换
static func safeString(_ value: Any?) -> String?

/// 安全布尔值转换
static func safeBool(_ value: Any?) -> Bool?
```

#### 数值处理工具

```swift
/// 限制数值范围
static func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T

/// 安全数组元素访问
static func safeArrayElement<T>(_ array: [T], at index: Int) -> T?

/// 安全字典值访问
static func safeDictionaryValue<T>(_ dictionary: [String: Any], for key: String) -> T?
```

#### 性能测量工具

```swift
/// 测量同步函数执行时间
static func measureExecutionTime<T>(_ operation: () -> T) -> (result: T, time: TimeInterval)

/// 测量异步函数执行时间
static func measureExecutionTimeAsync<T>(_ operation: @escaping () async -> T) async -> (result: T, time: TimeInterval)

/// 打印性能统计
static func printPerformanceStats(_ label: String, time: TimeInterval)
```

#### 调试工具

```swift
/// 调试打印
static func debugPrint(_ message: String, file: String = #file, function: String = #function, line: Int = #line)

/// 格式化错误信息
static func formatError(_ error: Error) -> String

/// 获取调用栈信息
static func getCallStack() -> [String]
```

---

## 协议

### MonitorLatencyDelegate

延迟监控器的代理协议。

```swift
protocol MonitorLatencyDelegate: AnyObject {
    /// 延迟更新回调
    func monitor(_ monitor: MonitorLatency, didUpdateLatency latency: TimeInterval, for endpoint: ServiceEndpoint)
    
    /// 监控失败回调
    func monitor(_ monitor: MonitorLatency, didFailWithError error: MonitorError, for endpoint: ServiceEndpoint)
}
```

**继承关系**：无

**要求**：`AnyObject`

---

### MonitorNetworkDelegate

网络监控器的代理协议。

```swift
protocol MonitorNetworkDelegate: AnyObject {
    /// 速度更新回调
    func monitor(_ monitor: MonitorNetwork, didUpdateSpeed speed: Double)
    
    /// 监控失败回调
    func monitor(_ monitor: MonitorNetwork, didFailWithError error: MonitorError)
}
```

**继承关系**：无

**要求**：`AnyObject`

---

## 枚举

### DisplayMode

显示模式枚举。

```swift
enum DisplayMode: String, CaseIterable {
    case serviceLatency = "LLM"    // AI 服务延迟
    case networkSpeed = "Net"      // 网络速度
}
```

**原始值类型**：`String`

**协议遵循**：`CaseIterable`

**用例**：
- 在状态栏显示不同的监控信息
- 用户可以在菜单中切换显示模式

---

### MonitorError

监控错误类型枚举。

```swift
enum MonitorError: Error, LocalizedError {
    case timeout              // 连接超时
    case connectionFailed     // 连接失败
    case networkError(Error)  // 网络错误
    case invalidEndpoint      // 无效端点
    case sysctlError(String)  // 系统调用错误
}
```

**继承关系**：`Error`, `LocalizedError`

**用例**：
- 错误处理和用户提示
- 日志记录和调试
- 重试机制触发

---

## 结构体

### ServiceEndpoint

服务端点配置结构体。

```swift
struct ServiceEndpoint: Codable, Equatable {
    /// 服务名称
    let name: String
    
    /// 服务主机
    let host: String
    
    /// 服务端口
    let port: UInt16
    
    /// 是否启用
    var isEnabled: Bool
    
    /// 自定义描述
    var description: String?
}
```

**协议遵循**：`Codable`, `Equatable`

**用例**：
- 配置 AI 服务端点
- 网络连接建立
- 用户界面显示

---

### MonitorResult

监控结果结构体。

```swift
struct MonitorResult {
    /// 监控时间戳
    let timestamp: Date
    
    /// 监控值
    let value: Double
    
    /// 监控单位
    let unit: String
    
    /// 是否成功
    let isSuccess: Bool
    
    /// 错误信息（如果失败）
    let error: MonitorError?
}
```

**协议遵循**：无

**用例**：
- 监控数据存储
- 历史记录显示
- 性能分析

---

## 常量

### MonitorConstants

监控相关的常量定义。

```swift
struct MonitorConstants {
    /// 连接超时时间
    static let connectionTimeout: TimeInterval = 3.0
    
    /// 最大重试次数
    static let maxRetries = 3
    
    /// 初始重试延迟
    static let initialRetryDelay: TimeInterval = 1.0
    
    /// 最大重试延迟
    static let maxRetryDelay: TimeInterval = 30.0
    
    /// 最大合理速度（MB/s）
    static let maxReasonableSpeed: Double = 1000.0
    
    /// 网络统计重置阈值
    static let networkStatsResetThreshold: UInt64 = 1000000000
}
```

**用途**：
- 配置监控参数
- 限制重试行为
- 验证数据有效性

---

### AppConstants

应用级常量定义。

```swift
struct AppConstants {
    /// 应用名称
    static let appName = "Moni"
    
    /// 应用版本
    static let appVersion = "1.06"
    
    /// 构建版本
    static let buildVersion = "1"
    
    /// 状态栏更新间隔
    static let statusBarUpdateInterval: TimeInterval = 0.1
    
    /// 菜单刷新间隔
    static let menuRefreshInterval: TimeInterval = 1.0
}
```

**用途**：
- 应用标识
- 版本信息
- 界面更新配置

---

## 扩展

### String 扩展

```swift
extension String {
    /// 转换为安全的文件名
    var safeFileName: String
    
    /// 截取指定长度
    func truncated(to length: Int, trailing: String) -> String
    
    /// 是否为空或只包含空白字符
    var isBlank: Bool
}
```

### Date 扩展

```swift
extension Date {
    /// 格式化时间差
    func timeAgoSinceNow() -> String
    
    /// 是否在指定时间范围内
    func isWithin(_ interval: TimeInterval, of date: Date) -> Bool
}
```

### Array 扩展

```swift
extension Array where Element: Equatable {
    /// 安全移除元素
    mutating func safeRemove(_ element: Element) -> Bool
    
    /// 获取随机元素
    func randomElement() -> Element?
}
```

---

## 使用示例

### 基本监控设置

```swift
// 创建监控器
let latencyMonitor = MonitorLatency(queueLabel: "latency", interval: 1.0)
let networkMonitor = MonitorNetwork(queueLabel: "network", interval: 2.0)

// 设置代理
latencyMonitor.delegate = self
networkMonitor.delegate = self

// 启动监控
latencyMonitor.startMonitoring()
networkMonitor.startMonitoring()
```

### 配置管理

```swift
// 获取配置管理器
let config = ConfigurationManager.shared

// 设置配置
config.displayMode = .serviceLatency
config.monitoringInterval = 1.0
config.notificationsEnabled = true

// 保存配置
config.notifyConfigurationChanged()
```

### 错误处理

```swift
// 实现代理方法
func monitor(_ monitor: MonitorLatency, didFailWithError error: MonitorError) {
    switch error {
    case .timeout:
        print("连接超时，将进行重试")
    case .connectionFailed:
        print("连接失败：\(error.localizedDescription)")
    default:
        print("未知错误：\(error)")
    }
}
```

### 工具函数使用

```swift
// 安全转换
let value = Utilities.safeInt("123") ?? 0

// 性能测量
let (result, time) = Utilities.measureExecutionTime {
    performExpensiveOperation()
}
print("操作耗时：\(time) 秒")

// 调试信息
Utilities.debugPrint("监控器状态更新")
```

---

## 版本兼容性

### Swift 版本
- **最低版本**：Swift 5.0
- **推荐版本**：Swift 5.9+

### macOS 版本
- **最低版本**：macOS 15.0
- **推荐版本**：macOS 15.0+

### Xcode 版本
- **最低版本**：Xcode 15.0
- **推荐版本**：Xcode 15.0+

---

## 注意事项

### 线程安全
- 所有 UI 更新必须在主线程执行
- 使用 `DispatchQueue.main.async` 确保线程安全
- 配置操作使用专用队列避免阻塞

### 内存管理
- 使用 `weak` 引用避免循环引用
- 及时清理网络连接和定时器
- 在 `deinit` 中释放资源

### 错误处理
- 始终实现错误处理逻辑
- 提供用户友好的错误信息
- 记录详细的错误日志用于调试

### 性能考虑
- 避免在主线程执行耗时操作
- 合理设置监控间隔
- 使用适当的队列优先级

---

*API 参考文档 - 最后更新：2025年1月*
