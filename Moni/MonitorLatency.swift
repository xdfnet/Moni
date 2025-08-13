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

import Foundation
import Network

/// 监控结果回调协议
protocol MonitorLatencyDelegate: AnyObject {
    func monitor(_ monitor: MonitorLatency, didUpdateLatency latency: TimeInterval, for endpoint: ServiceEndpoint)
    func monitor(_ monitor: MonitorLatency, didFailWithError error: MonitorError, for endpoint: ServiceEndpoint)
}

class MonitorLatency: BaseMonitor {
    
    // MARK: - 属性
    
    weak var delegate: MonitorLatencyDelegate?
    
    private var currentEndpoint: ServiceEndpoint?
    private var retryCount: Int = 0
    private var currentConnection: NWConnection?
    private var isRetrying: Bool = false
    
    // MARK: - 初始化
    
    override init(queueLabel: String, interval: TimeInterval) {
        super.init(queueLabel: queueLabel, interval: interval)
        self.errorDelegate = self
    }
    
    // MARK: - 公共方法
    
    /// 开始监控指定端点
    func startMonitoring(_ endpoint: ServiceEndpoint) {
        stopMonitoring()
        currentEndpoint = endpoint
        retryCount = 0
        isRetrying = false
        
        super.startMonitoring()
    }
    
    /// 停止监控并重置状态
    override func stopMonitoring() {
        super.stopMonitoring()
        cleanupCurrentConnection()
        currentEndpoint = nil
        retryCount = 0
        isRetrying = false
    }
    
    // MARK: - BaseMonitor 实现
    
    override func performMonitoring() {
        guard let endpoint = currentEndpoint else { return }
        
        // 避免重复连接
        guard currentConnection == nil && !isRetrying else { return }
        
        pingEndpoint(endpoint)
    }
    
    override func cleanupResources() {
        cleanupCurrentConnection()
    }
    
    // MARK: - 私有方法
    
    /// 执行一次 TCP 探测并计算时延
    private func pingEndpoint(_ endpoint: ServiceEndpoint) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 创建连接
        let connection = NWConnection(
            host: NWEndpoint.Host(endpoint.host),
            port: NWEndpoint.Port(integerLiteral: UInt16(endpoint.port)),
            using: .tcp
        )
        
        currentConnection = connection
        connection.start(queue: queue)
        
        // 设置超时处理：使用统一常量
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            self?.handleConnectionTimeout(for: endpoint, startTime: startTime)
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + MonitorConstants.connectionTimeout, execute: timeoutWorkItem)
        
        connection.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionStateChange(state, for: endpoint, startTime: startTime, timeoutWorkItem: timeoutWorkItem)
        }
    }
    
    /// 处理连接状态变化
    private func handleConnectionStateChange(_ state: NWConnection.State, for endpoint: ServiceEndpoint, startTime: CFAbsoluteTime, timeoutWorkItem: DispatchWorkItem) {
        switch state {
        case .ready:
            timeoutWorkItem.cancel()
            let latency = CFAbsoluteTimeGetCurrent() - startTime
            handleSuccessfulConnection(latency: latency, for: endpoint)
            
        case .failed(let error):
            timeoutWorkItem.cancel()
            handleConnectionFailure(error: MonitorError.networkError(error), for: endpoint, startTime: startTime)
            
        case .cancelled:
            timeoutWorkItem.cancel()
            // 连接被取消，不需要特殊处理
            
        case .waiting(let error):
            // 连接等待状态，记录日志但不视为失败
            logConnectionWaiting(error: error, for: endpoint)
            
        case .preparing:
            // 连接准备中，正常状态
            break
            
        case .setup:
            // 连接设置中，正常状态
            break
            
        @unknown default:
            // 处理未来可能的新状态
            logUnknownConnectionState(state, for: endpoint)
        }
    }
    
    /// 处理连接成功
    private func handleSuccessfulConnection(latency: TimeInterval, for endpoint: ServiceEndpoint) {
        cleanupCurrentConnection()
        retryCount = 0  // 重置重试计数
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.monitor(self, didUpdateLatency: latency, for: endpoint)
        }
    }
    
    /// 处理连接超时
    private func handleConnectionTimeout(for endpoint: ServiceEndpoint, startTime: CFAbsoluteTime) {
        cleanupCurrentConnection()
        handleConnectionFailure(error: MonitorError.timeout, for: endpoint, startTime: startTime)
    }
    
    /// 统一的失败处理：支持智能重试，超过上限后上报失败
    private func handleConnectionFailure(error: MonitorError, for endpoint: ServiceEndpoint, startTime: CFAbsoluteTime) {
        retryCount += 1
        
        if retryCount <= MonitorConstants.maxRetries {
            // 智能重试：指数退避 + 抖动
            let baseDelay = MonitorConstants.retryDelay * pow(2.0, Double(retryCount - 1))
            let jitter = Double.random(in: 0.1...0.3) * baseDelay
            let finalDelay = min(baseDelay + jitter, MonitorConstants.maxRetryDelay)
            
            isRetrying = true
            
            DispatchQueue.global().asyncAfter(deadline: .now() + finalDelay) { [weak self] in
                self?.isRetrying = false
                self?.pingEndpoint(endpoint)
            }
            
            logRetryAttempt(retryCount: retryCount, delay: finalDelay, for: endpoint)
        } else {
            // 超过最大重试次数，通知失败
            cleanupCurrentConnection()
            retryCount = 0  // 重置计数器，等待下一个监控周期
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.monitor(self, didFailWithError: error, for: endpoint)
            }
            
            logMaxRetriesReached(for: endpoint, error: error)
        }
    }
    
    /// 清理当前连接
    private func cleanupCurrentConnection() {
        currentConnection?.cancel()
        currentConnection = nil
    }
    
    /// 记录连接等待状态
    private func logConnectionWaiting(error: NWError, for endpoint: ServiceEndpoint) {
        #if DEBUG
        print("[MonitorLatency] Connection waiting for \(endpoint.name): \(error.localizedDescription)")
        #endif
    }
    
    /// 记录未知连接状态
    private func logUnknownConnectionState(_ state: NWConnection.State, for endpoint: ServiceEndpoint) {
        #if DEBUG
        print("[MonitorLatency] Unknown connection state for \(endpoint.name): \(state)")
        #endif
    }
    
    /// 记录重试尝试
    private func logRetryAttempt(retryCount: Int, delay: TimeInterval, for endpoint: ServiceEndpoint) {
        #if DEBUG
        print("[MonitorLatency] Retry attempt \(retryCount) for \(endpoint.name) in \(String(format: "%.2f", delay))s")
        #endif
    }
    
    /// 记录达到最大重试次数
    private func logMaxRetriesReached(for endpoint: ServiceEndpoint, error: MonitorError) {
        #if DEBUG
        print("[MonitorLatency] Max retries reached for \(endpoint.name): \(error.localizedDescription)")
        #endif
    }
}

// MARK: - ErrorHandling 实现
extension MonitorLatency: ErrorHandling {
    func logError(_ error: MonitorError, context: String) {
        #if DEBUG
        print("[\(context)] Error: \(error.localizedDescription)")
        #endif
    }
}