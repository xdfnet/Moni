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
//  - 支持按类别分组，便于菜单分类显示
//  - 使用 SharedTypes.swift 中定义的 AppConstants 和 ServiceEndpoint
//  - 支持端点验证和配置重载
//
import Foundation

// MARK: - 服务类别
enum ServiceCategory: String, CaseIterable {
    case aiServices = "AI Services"
    case development = "Development"
    case network = "Network"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - 带类别的服务端点
struct CategorizedServiceEndpoint {
    let category: ServiceCategory
    let endpoints: [ServiceEndpoint]
}

class ServiceManager {
    static let shared = ServiceManager()
    
    private(set) var categorizedEndpoints: [CategorizedServiceEndpoint] = []
    private(set) var allEndpoints: [ServiceEndpoint] = []
    
    private init() {
        loadEndpoints()
    }
    
    private func loadEndpoints() {
        // 按类别组织服务配置
        let aiServices = [
            ServiceEndpoint(name: "Claude", host: "api.anthropic.com", port: 443),
            ServiceEndpoint(name: "Gemini", host: "generativelanguage.googleapis.com", port: 443),
            ServiceEndpoint(name: "DeepSeek", host: "api.deepseek.com", port: 443),
            ServiceEndpoint(name: "GLM", host: "open.bigmodel.cn", port: 443),
            ServiceEndpoint(name: "Kimi", host: "api.moonshot.cn", port: 443),
        ]
        
        let developmentServices = [
            ServiceEndpoint(name: "Homebrew", host: "github.com", port: 443),
            ServiceEndpoint(name: "NPM", host: "registry.npmjs.org", port: 443),
            ServiceEndpoint(name: "PyPI", host: "pypi.org", port: 443),
            ServiceEndpoint(name: "Maven", host: "repo1.maven.org", port: 443),
        ]
        
        let networkServices = [
            ServiceEndpoint(name: "Docker", host: "registry-1.docker.io", port: 443),
            ServiceEndpoint(name: "Cursor", host: "api.cursor.sh", port: 443),
        ]
        
        // 构建分类结构
        categorizedEndpoints = [
            CategorizedServiceEndpoint(category: .aiServices, endpoints: aiServices),
            CategorizedServiceEndpoint(category: .development, endpoints: developmentServices),
            CategorizedServiceEndpoint(category: .network, endpoints: networkServices)
        ]
        
        // 构建扁平列表（向后兼容）
        allEndpoints = aiServices + developmentServices + networkServices
    }
    
    // MARK: - 分类访问方法
    
    /// 获取指定类别的服务
    func getEndpoints(for category: ServiceCategory) -> [ServiceEndpoint] {
        return categorizedEndpoints.first { $0.category == category }?.endpoints ?? []
    }
    
    /// 获取所有类别
    var categories: [ServiceCategory] {
        return ServiceCategory.allCases
    }
    
    // MARK: - 向后兼容方法
    
    /// 获取所有端点（扁平列表）
    var endpoints: [ServiceEndpoint] {
        return allEndpoints
    }
    
    func getEndpoint(by name: String) -> ServiceEndpoint? {
        return allEndpoints.first { $0.name == name }
    }
    
    func reloadConfig() {
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
        return allEndpoints.filter { validateEndpoint($0) }
    }
}