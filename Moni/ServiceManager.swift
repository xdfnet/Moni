//
//  ServiceManager.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  服务配置管理
//
//  功能说明：
//  - ServiceManager 负责管理内置的 AI 服务端点配置
//  - 使用 SharedTypes.swift 中定义的 AppConstants 和 ServiceEndpoint
//  - 支持端点验证和配置重载
//
import Foundation

class ServiceManager {
    static let shared = ServiceManager()
    
    private(set) var endpoints: [ServiceEndpoint] = []
    
    private init() {
        loadEndpoints()
    }
    
    private func loadEndpoints() {
        // 直接使用内置的服务配置，更简单可靠
        endpoints = [
            ServiceEndpoint(name: "Claude", host: "api.anthropic.com", port: 443),
            ServiceEndpoint(name: "Gemini", host: "generativelanguage.googleapis.com", port: 443),
            ServiceEndpoint(name: "DeepSeek", host: "api.deepseek.com", port: 443),
            ServiceEndpoint(name: "Kimi", host: "api.moonshot.cn", port: 443)
        ]
    }
    
    func getEndpoint(by name: String) -> ServiceEndpoint? {
        // 根据服务名查找端点
        return endpoints.first { $0.name == name }
    }
    
    func reloadConfig() {
        // 重新加载内置配置
        loadEndpoints()
    }
    
    // MARK: - 验证方法
    
    /// 验证端点配置的有效性
    func validateEndpoint(_ endpoint: ServiceEndpoint) -> Bool {
        return !endpoint.name.isEmpty && 
               !endpoint.host.isEmpty && 
               endpoint.port > 0 && 
               endpoint.port <= 65535
    }
    
    /// 获取所有有效的端点
    var validEndpoints: [ServiceEndpoint] {
        return endpoints.filter { validateEndpoint($0) }
    }
}