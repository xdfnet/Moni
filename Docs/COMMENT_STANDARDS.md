# Moni 项目注释规范

## 📝 概述

本文档定义了 Moni 项目的统一注释规范，确保所有代码文件都遵循一致的注释风格，提高代码的可读性和可维护性。

## 🏗️ 文件头注释规范

### 标准格式

```swift
//
//  FileName.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  文件功能描述
//
//  功能说明：
//  - 功能点1
//  - 功能点2
//  - 功能点3
//
```

### 示例

```swift
//
//  MonitorLatency.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  TCP 探活与延迟测量（毫秒）
//
//  功能说明：
//  - 通过 Network.framework 建立到目标主机端口的 TCP 连接
//  - 连接 ready 的时间差即为近似网络时延
//  - 内置超时与最多重试次数，失败时通过代理上报
//  - 支持指数退避重试和智能错误恢复
//
```

## 🏷️ MARK 注释规范

### 标准格式

```swift
// MARK: - 分组名称

// 或者

// MARK: 分组名称
```

### 常用分组

- `// MARK: - 属性`
- `// MARK: - 初始化`
- `// MARK: - 公共方法`
- `// MARK: - 私有方法`
- `// MARK: - 生命周期管理`
- `// MARK: - 事件处理`
- `// MARK: - 工具方法`
- `// MARK: - 协议实现`

### 示例

```swift
// MARK: - 属性

/// 监控状态
private(set) var isMonitoring: Bool = false

// MARK: - 初始化

init(queueLabel: String, interval: TimeInterval) {
    // 初始化代码
}

// MARK: - 公共方法

/// 开始监控
func startMonitoring() {
    // 方法实现
}
```

## 💬 属性注释规范

### 标准格式

```swift
/// 属性描述
private var propertyName: PropertyType
```

### 示例

```swift
/// UI 组件
private var statusBarItem: NSStatusItem?

/// 监控服务
private let monitor = MonitorLatency(...)

/// 状态数据
private var currentEndpoint: ServiceEndpoint?
```

## 🔧 方法注释规范

### 标准格式

```swift
/// 方法功能描述
/// - Parameter param1: 参数1描述
/// - Parameter param2: 参数2描述
/// - Returns: 返回值描述
func methodName(param1: Type1, param2: Type2) -> ReturnType
```

### 示例

```swift
/// 开始监控指定端点
/// - Parameter endpoint: 要监控的服务端点
func startMonitoring(_ endpoint: ServiceEndpoint) {
    // 方法实现
}

/// 更新监控间隔
/// - Parameter newInterval: 新的监控间隔（秒）
func updateInterval(_ newInterval: TimeInterval) {
    // 方法实现
}
```

## 📱 行内注释规范

### 标准格式

```swift
// 注释内容
```

### 示例

```swift
// 隐藏 Dock 图标，仅保留菜单栏图标
NSApp.setActivationPolicy(.accessory)

// 初始化菜单栏管理器（创建状态栏图标与菜单）
menuBarManager = MenuBarController()

// 退出前清理资源（停止定时器、释放对象）
menuBarManager?.cleanup()
```

## 🐛 调试注释规范

### 标准格式

```swift
#if DEBUG
print("[Context] Debug message")
#endif
```

### 示例

```swift
#if DEBUG
print("[MonitorLatency] Connection waiting for \(endpoint.name): \(error.localizedDescription)")
#endif
```

## 📚 协议注释规范

### 标准格式

```swift
/// 协议功能描述
protocol ProtocolName: AnyObject {
    // 协议要求
}
```

### 示例

```swift
/// 监控结果回调协议
protocol MonitorLatencyDelegate: AnyObject {
    /// 延迟更新回调
    func monitor(_ monitor: MonitorLatency, didUpdateLatency latency: TimeInterval, for endpoint: ServiceEndpoint)
    
    /// 监控失败回调
    func monitor(_ monitor: MonitorLatency, didFailWithError error: MonitorError, for endpoint: ServiceEndpoint)
}
```

## 🎯 枚举注释规范

### 标准格式

```swift
/// 枚举功能描述
enum EnumName: String, CaseIterable {
    /// 枚举值1描述
    case value1 = "rawValue1"
    /// 枚举值2描述
    case value2 = "rawValue2"
}
```

### 示例

```swift
/// 显示模式枚举
enum DisplayMode: String, CaseIterable {
    /// 服务延迟模式
    case serviceLatency = "Latency"
    /// 网络速度模式
    case networkSpeed = "Speed"
}
```

## 🔍 检查清单

在提交代码前，请确保：

- [ ] 文件头注释格式正确
- [ ] 所有公共属性和方法都有 `///` 注释
- [ ] 使用 `// MARK:` 进行代码分组
- [ ] 行内注释清晰明了
- [ ] 调试代码使用 `#if DEBUG` 包装
- [ ] 注释内容准确且有用

## 📖 参考资源

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Apple Documentation](https://developer.apple.com/documentation/)
- [Swift Style Guide](https://github.com/raywenderlich/swift-style-guide)

---

*最后更新：2025年1月*
