//
//  Utilities.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  工具类：提供常用的辅助功能
//
//  功能说明：
//  - 统一格式化、验证等常用功能
//  - 提供线程安全的回调执行
//  - 减少代码重复
//  - 包含数值工具、集合工具、性能工具和调试工具
//

import Foundation

// MARK: - 工具类
struct Utilities {
    
    // MARK: - 格式化工具
    
    /// 格式化延迟时间（毫秒）
    static func formatLatency(_ latency: TimeInterval) -> String {
        let latencyMs = latency * 1000
        return String(format: "%.0fms", latencyMs)
    }
    
    /// 格式化网络速度（MB/s）
    static func formatSpeed(_ speed: Double) -> String {
        return String(format: "%.2fMB/s", speed)
    }
    
    /// 格式化时间间隔
    static func formatInterval(_ interval: TimeInterval) -> String {
        if interval < 1.0 {
            return "\(interval)s"
        } else if interval == 1.0 {
            return "1s"
        } else {
            return "\(Int(interval))s"
        }
    }
    
    // MARK: - 验证工具
    
    /// 验证端点配置
    static func validateEndpoint(_ endpoint: ServiceEndpoint) -> Bool {
        return !endpoint.name.isEmpty && 
               !endpoint.host.isEmpty && 
               endpoint.port > 0 && 
               endpoint.port <= 65535
    }
    
    /// 验证监控间隔
    static func validateInterval(_ interval: TimeInterval) -> Bool {
        return interval >= MonitorConstants.minInterval && 
               interval <= MonitorConstants.maxInterval
    }
    
    // MARK: - 线程安全工具
    
    /// 安全的主线程回调执行
    static func safeMainQueueCallback(_ callback: @escaping () -> Void) {
        if Thread.isMainThread {
            callback()
        } else {
            DispatchQueue.main.async(execute: callback)
        }
    }
    
    /// 带 weak self 检查的主线程回调
    static func safeMainQueueCallback<T: AnyObject>(_ object: T, _ callback: @escaping (T) -> Void) {
        safeMainQueueCallback { [weak object] in
            guard let object = object else { return }
            callback(object)
        }
    }
    

    
    // MARK: - 时间工具
    
    /// 获取当前时间戳
    static func currentTimestamp() -> CFAbsoluteTime {
        return CFAbsoluteTimeGetCurrent()
    }
    
    /// 计算时间差
    static func timeDifference(from startTime: CFAbsoluteTime) -> TimeInterval {
        return currentTimestamp() - startTime
    }
    
    // MARK: - 字符串工具
    
    /// 安全的字符串截取
    static func safeSubstring(_ string: String, from startIndex: Int, to endIndex: Int) -> String {
        let start = string.index(string.startIndex, offsetBy: max(0, startIndex))
        let end = string.index(string.startIndex, offsetBy: min(string.count, endIndex))
        return String(string[start..<end])
    }
    
    /// 检查字符串是否为空或只包含空白字符
    static func isBlank(_ string: String?) -> Bool {
        guard let string = string else { return true }
        return string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - 数值工具
    
    /// 安全的数值转换
    static func safeInt(_ value: Any?, defaultValue: Int = 0) -> Int {
        if let intValue = value as? Int {
            return intValue
        } else if let stringValue = value as? String, let intValue = Int(stringValue) {
            return intValue
        } else if let doubleValue = value as? Double {
            return Int(doubleValue)
        }
        return defaultValue
    }
    
    /// 安全的 Double 转换
    static func safeDouble(_ value: Any?, defaultValue: Double = 0.0) -> Double {
        if let doubleValue = value as? Double {
            return doubleValue
        } else if let stringValue = value as? String, let doubleValue = Double(stringValue) {
            return doubleValue
        } else if let intValue = value as? Int {
            return Double(intValue)
        }
        return defaultValue
    }
    
    /// 限制数值范围
    static func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        return Swift.max(min, Swift.min(value, max))
    }
    
    // MARK: - 集合工具
    
    /// 安全的数组访问
    static func safeArrayElement<T>(_ array: [T], at index: Int) -> T? {
        guard index >= 0 && index < array.count else { return nil }
        return array[index]
    }
    
    /// 安全的字典访问
    static func safeDictionaryValue<T>(_ dictionary: [String: Any], for key: String, as type: T.Type) -> T? {
        return dictionary[key] as? T
    }
    
    // MARK: - 性能工具
    
    /// 测量代码执行时间
    static func measureExecutionTime<T>(_ operation: () throws -> T) rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
    
    /// 异步测量代码执行时间
    static func measureExecutionTimeAsync<T>(_ operation: @escaping () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
    
    // MARK: - 调试工具
    
    /// 打印调试信息（仅在 DEBUG 模式下）
    static func debugPrint(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("[\(fileName):\(line)] \(function): \(message)")
        #endif
    }
    
    /// 打印性能统计
    static func printPerformanceStats(_ name: String, duration: TimeInterval) {
        #if DEBUG
        print("⏱️ [\(name)] Duration: \(String(format: "%.3f", duration))s")
        #endif
    }
}

