//
//  ConfigurationManager.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  配置管理器：负责应用配置的加载、保存和验证
//
//  功能说明：
//  - 统一管理所有应用配置
//  - 支持用户自定义配置
//  - 提供配置验证和默认值
//  - 支持配置热重载和导入/导出
//

import Foundation

// MARK: - 配置键定义
struct ConfigKeys {
    static let displayMode = "currentDisplayMode"
    static let monitoringInterval = "currentMonitoringInterval"
    static let lastSelectedService = "lastSelectedService"
    static let customEndpoints = "customEndpoints"
    static let enableNotifications = "enableNotifications"
    static let autoRetry = "autoRetry"
    static let maxRetries = "maxRetries"
    static let connectionTimeout = "connectionTimeout"
}

// MARK: - 配置管理器
class ConfigurationManager {
    
    // MARK: - 单例
    static let shared = ConfigurationManager()
    
    // MARK: - 属性
    private let defaults = UserDefaults.standard
    private let configQueue = DispatchQueue(label: "com.moni.config", qos: .utility)
    
    // MARK: - 配置变更通知
    var onConfigurationChanged: (() -> Void)?
    
    // MARK: - 初始化
    private init() {
        setupDefaultConfiguration()
        registerDefaults()
    }
    
    // MARK: - 配置设置
    
    /// 设置显示模式
    func setDisplayMode(_ mode: DisplayMode) {
        configQueue.async {
            self.defaults.set(mode.rawValue, forKey: ConfigKeys.displayMode)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取显示模式
    func getDisplayMode() -> DisplayMode {
        if let rawValue = defaults.string(forKey: ConfigKeys.displayMode),
           let mode = DisplayMode(rawValue: rawValue) {
            return mode
        }
        return .serviceLatency
    }
    
    /// 设置监控间隔
    func setMonitoringInterval(_ interval: TimeInterval) {
        let validatedInterval = Utilities.clamp(interval, 
                                              min: MonitorConstants.minInterval, 
                                              max: MonitorConstants.maxInterval)
        
        configQueue.async {
            self.defaults.set(validatedInterval, forKey: ConfigKeys.monitoringInterval)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取监控间隔
    func getMonitoringInterval() -> TimeInterval {
        let interval = defaults.double(forKey: ConfigKeys.monitoringInterval)
        if interval > 0 {
            return Utilities.clamp(interval, 
                                 min: MonitorConstants.minInterval, 
                                 max: MonitorConstants.maxInterval)
        }
        return MonitorConstants.defaultUserInterval
    }
    
    /// 设置最后选择的服务
    func setLastSelectedService(_ serviceName: String) {
        configQueue.async {
            self.defaults.set(serviceName, forKey: ConfigKeys.lastSelectedService)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取最后选择的服务
    func getLastSelectedService() -> String? {
        return defaults.string(forKey: ConfigKeys.lastSelectedService)
    }
    
    /// 设置自定义端点
    func setCustomEndpoints(_ endpoints: [ServiceEndpoint]) {
        let customData = endpoints.map { endpoint in
            [
                "name": endpoint.name,
                "host": endpoint.host,
                "port": endpoint.port
            ]
        }
        
        configQueue.async {
            self.defaults.set(customData, forKey: ConfigKeys.customEndpoints)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取自定义端点
    func getCustomEndpoints() -> [ServiceEndpoint] {
        guard let customData = defaults.array(forKey: ConfigKeys.customEndpoints) as? [[String: Any]] else {
            return []
        }
        
        return customData.compactMap { data in
            guard let name = data["name"] as? String,
                  let host = data["host"] as? String,
                  let port = data["port"] as? Int else {
                return nil
            }
            return ServiceEndpoint(name: name, host: host, port: port)
        }
    }
    
    /// 设置是否启用通知
    func setEnableNotifications(_ enabled: Bool) {
        configQueue.async {
            self.defaults.set(enabled, forKey: ConfigKeys.enableNotifications)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取是否启用通知
    func getEnableNotifications() -> Bool {
        return defaults.bool(forKey: ConfigKeys.enableNotifications)
    }
    
    /// 设置是否自动重试
    func setAutoRetry(_ enabled: Bool) {
        configQueue.async {
            self.defaults.set(enabled, forKey: ConfigKeys.autoRetry)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取是否自动重试
    func getAutoRetry() -> Bool {
        return defaults.bool(forKey: ConfigKeys.autoRetry)
    }
    
    /// 设置最大重试次数
    func setMaxRetries(_ count: Int) {
        let validatedCount = Utilities.clamp(count, min: 1, max: 10)
        configQueue.async {
            self.defaults.set(validatedCount, forKey: ConfigKeys.maxRetries)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取最大重试次数
    func getMaxRetries() -> Int {
        let count = defaults.integer(forKey: ConfigKeys.maxRetries)
        return count > 0 ? count : MonitorConstants.maxRetries
    }
    
    /// 设置连接超时时间
    func setConnectionTimeout(_ timeout: TimeInterval) {
        let validatedTimeout = Utilities.clamp(timeout, min: 1.0, max: 30.0)
        configQueue.async {
            self.defaults.set(validatedTimeout, forKey: ConfigKeys.connectionTimeout)
            self.notifyConfigurationChanged()
        }
    }
    
    /// 获取连接超时时间
    func getConnectionTimeout() -> TimeInterval {
        let timeout = defaults.double(forKey: ConfigKeys.connectionTimeout)
        return timeout > 0 ? timeout : MonitorConstants.connectionTimeout
    }
    
    // MARK: - 配置管理
    
    /// 重置所有配置到默认值
    func resetToDefaults() {
        configQueue.async {
            let domain = Bundle.main.bundleIdentifier ?? "com.moni"
            self.defaults.removePersistentDomain(forName: domain)
            self.setupDefaultConfiguration()
            self.notifyConfigurationChanged()
        }
    }
    
    /// 导出配置
    func exportConfiguration() -> Data? {
        let config: [String: Any] = [
            "displayMode": getDisplayMode().rawValue,
            "monitoringInterval": getMonitoringInterval(),
            "lastSelectedService": getLastSelectedService() ?? "",
            "customEndpoints": getCustomEndpoints().map { [
                "name": $0.name,
                "host": $0.host,
                "port": $0.port
            ]},
            "enableNotifications": getEnableNotifications(),
            "autoRetry": getAutoRetry(),
            "maxRetries": getMaxRetries(),
            "connectionTimeout": getConnectionTimeout(),
            "exportDate": Date().timeIntervalSince1970
        ]
        
        return try? JSONSerialization.data(withJSONObject: config, options: .prettyPrinted)
    }
    
    /// 导入配置
    func importConfiguration(_ data: Data) -> Bool {
        guard let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        
        configQueue.async {
            // 验证并应用配置
            if let displayMode = config["displayMode"] as? String,
               let mode = DisplayMode(rawValue: displayMode) {
                self.setDisplayMode(mode)
            }
            
            if let interval = config["monitoringInterval"] as? TimeInterval {
                self.setMonitoringInterval(interval)
            }
            
            if let serviceName = config["lastSelectedService"] as? String {
                self.setLastSelectedService(serviceName)
            }
            
            if let customEndpointsData = config["customEndpoints"] as? [[String: Any]] {
                let customEndpoints = customEndpointsData.compactMap { (data: [String: Any]) -> ServiceEndpoint? in
                    guard let name = data["name"] as? String,
                          let host = data["host"] as? String,
                          let port = data["port"] as? Int else {
                        return nil
                    }
                    return ServiceEndpoint(name: name, host: host, port: port)
                }
                self.setCustomEndpoints(customEndpoints)
            }
            
            if let enableNotifications = config["enableNotifications"] as? Bool {
                self.setEnableNotifications(enableNotifications)
            }
            
            if let autoRetry = config["autoRetry"] as? Bool {
                self.setAutoRetry(autoRetry)
            }
            
            if let maxRetries = config["maxRetries"] as? Int {
                self.setMaxRetries(maxRetries)
            }
            
            if let connectionTimeout = config["connectionTimeout"] as? TimeInterval {
                self.setConnectionTimeout(connectionTimeout)
            }
            
            self.notifyConfigurationChanged()
        }
        
        return true
    }
    
    // MARK: - 私有方法
    
    /// 设置默认配置
    private func setupDefaultConfiguration() {
        // 这里可以设置一些默认值
    }
    
    /// 注册默认值
    private func registerDefaults() {
        let defaultValues: [String: Any] = [
            ConfigKeys.enableNotifications: true,
            ConfigKeys.autoRetry: true,
            ConfigKeys.maxRetries: MonitorConstants.maxRetries,
            ConfigKeys.connectionTimeout: MonitorConstants.connectionTimeout
        ]
        
        defaults.register(defaults: defaultValues)
    }
    
    /// 通知配置变更
    private func notifyConfigurationChanged() {
        DispatchQueue.main.async {
            self.onConfigurationChanged?()
        }
    }
}
