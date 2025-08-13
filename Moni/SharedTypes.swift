//
//  SharedTypes.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  共享类型定义
//
//  功能说明：
//  - 定义应用中使用的基础类型和常量，确保编译顺序正确
//  - 包含应用常量、服务端点、错误类型和监控常量
//  - 提供统一的类型定义和常量管理
//

import Foundation

// 应用常量
struct AppConstants {
    // MARK: - 显示常量
    static let defaultValue = "---"
    static let errorMessage = "Error"
    static let timeoutMessage = "Timeout"
    
    // MARK: - 版本信息（从 Info.plist 读取）
    struct Version {
        static var current: String {
            return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown Version"
        }
        
        static var build: String {
            return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        }
        
        static var description: String {
            return Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? ""
        }
        
        static var displayVersion: String {
            return "v\(current)"
        }
    }
    
    // MARK: - 应用信息
    struct AppInfo {
        static let name = "Moni - AI Service Latency Monitor"
        static let description = """
        A lightweight macOS menu bar app for real-time monitoring of AI service network latency and bandwidth usage.
        
        © 2024 Moni App
        """
        static let confirmButtonText = "OK"
    }
}

// 服务端点定义
struct ServiceEndpoint {
    let name: String
    let host: String
    let port: Int
    
    init(name: String, host: String, port: Int = 443) {
        self.name = name
        self.host = host
        self.port = port
    }
}

// MARK: - 统一错误类型
enum MonitorError: Error, LocalizedError {
    case timeout
    case connectionFailed
    case networkError(Error)
    case invalidEndpoint
    case sysctlError(String)
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Connection timeout"
        case .connectionFailed:
            return "Connection failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidEndpoint:
            return "Invalid endpoint"
        case .sysctlError(let message):
            return "System error: \(message)"
        }
    }
}

// MARK: - 监控相关常量
struct MonitorConstants {
    // 连接相关
    static let connectionTimeout: TimeInterval = 3.0
    static let maxRetries = 3
    static let retryDelay: TimeInterval = 1.0
    static let maxRetryDelay: TimeInterval = 30.0  // 最大重试延迟
    
    // 监控间隔
    static let defaultLatencyInterval: TimeInterval = 0.5
    static let defaultNetworkInterval: TimeInterval = 0.5
    
    // 用户可配置的监控间隔选项
    static let availableIntervals: [TimeInterval] = [0.5, 1.0, 2.0, 5.0]
    static let defaultUserInterval: TimeInterval = 0.5
    
    // 新增：监控间隔限制
    static let minInterval: TimeInterval = 0.1
    static let maxInterval: TimeInterval = 10.0
    
    // 队列标识
    static let latencyQueueLabel = "com.moni.latency"
    static let networkQueueLabel = "com.moni.network"
    
    // 新增：网络配置
    static let networkBufferSize = 1024 * 1024 // 1MB
    static let maxConnectionAttempts = 5
    static let connectionRetryDelay: TimeInterval = 2.0
    
    // 新增：性能配置
    static let maxConcurrentConnections = 3
    static let connectionPoolTimeout: TimeInterval = 30.0
    
    // 新增：网络监控配置
    static let maxReasonableSpeed: Double = 1000.0  // 1000 MB/s 作为合理速度上限
    static let networkStatsResetThreshold: UInt64 = 1000 * 1024 * 1024  // 1GB 作为重置阈值
}

