//
//  MenuBarController.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  菜单栏控制器：负责状态栏文本展示与菜单交互
//
//  功能说明：
//  - 组合并展示当前模式下的状态文本（服务延迟 / 网络速度）
//  - 构建并响应菜单项（显示模式、服务选择、版本/构建信息、退出）
//  - 协调 MonitorLatency 与 MonitorNetwork 的启停
//
import Cocoa
import SwiftUI

// MARK: - 显示模式枚举
enum DisplayMode: String, CaseIterable {
    case serviceLatency = "LLM"
    case networkSpeed = "Net"
}

// MARK: - 菜单栏控制器
class MenuBarController: NSObject, MonitorLatencyDelegate, MonitorNetworkDelegate {
    
    // MARK: - 属性
    
    /// UI 组件
    private var statusBarItem: NSStatusItem?
    
    /// 监控服务
    private let monitor = MonitorLatency(queueLabel: MonitorConstants.latencyQueueLabel, interval: MonitorConstants.defaultLatencyInterval)
    private let networkStats = MonitorNetwork(queueLabel: MonitorConstants.networkQueueLabel, interval: MonitorConstants.defaultNetworkInterval)
    
    /// 状态数据
    private var currentEndpoint: ServiceEndpoint?
    private var currentLatency: String = AppConstants.defaultValue
    private var currentDownloadSpeed: String = AppConstants.defaultValue
    
    /// 状态指示器
    private var lastError: MonitorError?
    private var isHealthy: Bool = true
    
    /// 当前展示模式（切换时联动启停对应监控）
    private var currentDisplayMode: DisplayMode = .serviceLatency {
        didSet {
            saveSettings()
            updateCombinedDisplay()
            updateMonitoringState()
        }
    }
    
    /// 当前监控间隔（用户可配置）
    private var currentMonitoringInterval: TimeInterval = MonitorConstants.defaultUserInterval {
        didSet {
            saveSettings()
            updateMonitoringState()
        }
    }
    
    // MARK: - 初始化
    
    override init() {
        super.init()
        loadSettings()
        setupStatusBar()
        setupMonitor()
        setupDefaultMonitoring()
        updateCombinedDisplay()
    }
    
    // MARK: - 生命周期管理
    
    func cleanup() {
        monitor.stopMonitoring()
        networkStats.stopMonitoring()
        statusBarItem = nil
    }
    
    // MARK: - 私有方法
    
    /// 初始化状态栏按钮（等宽字体避免数值跳动）
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    /// 绑定代理与基础参数
    private func setupMonitor() {
        monitor.delegate = self
        monitor.updateInterval(currentMonitoringInterval)
        networkStats.delegate = self
    }
    
    /// 设置默认监控状态
    private func setupDefaultMonitoring() {
        if currentDisplayMode == .serviceLatency {
            // 优先使用已保存的服务，如果没有则默认选择 Claude
            if let endpoint = currentEndpoint {
                print("使用已保存的服务: \(endpoint.name)")
                switchToEndpoint(endpoint)
            } else if let claudeEndpoint = ServiceManager.shared.endpoints.first(where: { $0.name == "Claude" }) {
                print("使用默认服务: Claude")
                currentEndpoint = claudeEndpoint
                switchToEndpoint(claudeEndpoint)
            } else if let firstEndpoint = ServiceManager.shared.endpoints.first {
                print("使用第一个可用服务: \(firstEndpoint.name)")
                currentEndpoint = firstEndpoint
                switchToEndpoint(firstEndpoint)
            } else {
                print("警告: 没有可用的服务端点")
            }
        } else {
            networkStats.startMonitoring(interval: currentMonitoringInterval)
        }
    }
    
    /// 更新监控状态
    private func updateMonitoringState() {
        if currentDisplayMode == .serviceLatency {
            if let endpoint = currentEndpoint {
                monitor.startMonitoring(endpoint)
            }
            networkStats.stopMonitoring()
        } else {
            monitor.stopMonitoring()
            networkStats.startMonitoring(interval: currentMonitoringInterval)
        }
    }
    
    /// 点击状态栏按钮时动态创建菜单（避免菜单粘连）
    @objc private func statusBarButtonClicked() {
        statusBarItem?.menu = createMenu()
        statusBarItem?.button?.performClick(nil)
        statusBarItem?.menu = nil
    }
    
    /// 构建主菜单
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // 显示模式选择
        menu.addItem(createDisplayModeMenu())
        menu.addItem(NSMenuItem.separator())
        
        // LLM 服务选择
        menu.addItem(createServicesMenu())
        menu.addItem(NSMenuItem.separator())
        
        // 监控间隔设置
        menu.addItem(createMonitoringIntervalMenu())
        menu.addItem(NSMenuItem.separator())
        
        // About 信息
        menu.addItem(createAboutMenu())
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        menu.addItem(createQuitMenu())
        
        return menu
    }
    
    /// 创建显示模式菜单
    private func createDisplayModeMenu() -> NSMenuItem {
        let displayModeItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let displayModeSubmenu = NSMenu()
        
        for mode in DisplayMode.allCases {
            let item = NSMenuItem(
                title: mode.rawValue,
                action: #selector(displayModeSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (currentDisplayMode == mode) ? .on : .off
            displayModeSubmenu.addItem(item)
        }
        
        displayModeItem.submenu = displayModeSubmenu
        return displayModeItem
    }
    
    /// 创建监控间隔设置菜单
    private func createMonitoringIntervalMenu() -> NSMenuItem {
        let intervalItem = NSMenuItem(title: "Rate", action: nil, keyEquivalent: "")
        let intervalSubmenu = NSMenu()
        
        // 使用 MonitorConstants 中定义的可用间隔
        for interval in MonitorConstants.availableIntervals {
            let title: String
            if interval < 1.0 {
                title = "\(interval)s"  // 0.5s 而不是 500ms
            } else if interval == 1.0 {
                title = "1s"
            } else {
                title = "\(Int(interval))s"
            }
            
            let item = NSMenuItem(
                title: title,
                action: #selector(monitoringIntervalSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = interval
            item.state = (currentMonitoringInterval == interval) ? .on : .off
            intervalSubmenu.addItem(item)
        }
        
        intervalItem.submenu = intervalSubmenu
        return intervalItem
    }
    
    /// 创建服务选择菜单
    private func createServicesMenu() -> NSMenuItem {
        let servicesItem = NSMenuItem(title: "LLM", action: nil, keyEquivalent: "")
        let servicesSubmenu = NSMenu()
        
        for endpoint in ServiceManager.shared.endpoints {
            let item = NSMenuItem(
                title: endpoint.name,
                action: #selector(serviceSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = endpoint
            item.state = (endpoint.name == currentEndpoint?.name) ? .on : .off
            servicesSubmenu.addItem(item)
        }
        
        servicesItem.submenu = servicesSubmenu
        return servicesItem
    }
    
    /// 创建 About 菜单
    private func createAboutMenu() -> NSMenuItem {
        let aboutItem = NSMenuItem(title: "About", action: nil, keyEquivalent: "")
        let aboutSubmenu = NSMenu()
        
        // 版本信息
        let versionItem = NSMenuItem(
            title: "Version: \(AppConstants.Version.current)",
            action: nil,
            keyEquivalent: ""
        )
        versionItem.isEnabled = false
        aboutSubmenu.addItem(versionItem)
        
        // 构建信息
        let buildItem = NSMenuItem(
            title: "Build: \(AppConstants.Version.build)",
            action: nil,
            keyEquivalent: ""
        )
        buildItem.isEnabled = false
        aboutSubmenu.addItem(buildItem)
        
        // 分隔线
        aboutSubmenu.addItem(NSMenuItem.separator())
        
        // 版权信息
        let copyrightItem = NSMenuItem(
            title: "© 2025 Moni App",
            action: nil,
            keyEquivalent: ""
        )
        copyrightItem.isEnabled = false
        aboutSubmenu.addItem(copyrightItem)
        
        aboutItem.submenu = aboutSubmenu
        return aboutItem
    }
    
    /// 创建退出菜单
    private func createQuitMenu() -> NSMenuItem {
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        return quitItem
    }
    
    // MARK: - 菜单事件处理
    
    @objc private func displayModeSelected(_ sender: NSMenuItem) {
        guard let modeString = sender.representedObject as? String,
              let mode = DisplayMode(rawValue: modeString) else { return }
        currentDisplayMode = mode
    }
    
    @objc private func monitoringIntervalSelected(_ sender: NSMenuItem) {
        guard let interval = sender.representedObject as? TimeInterval else { return }
        currentMonitoringInterval = interval
    }
    
    @objc private func serviceSelected(_ sender: NSMenuItem) {
        guard let endpoint = sender.representedObject as? ServiceEndpoint else { return }
        switchToEndpoint(endpoint)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - 设置管理
    
    /// 从用户偏好读取当前模式和服务
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // 加载显示模式
        if let rawValue = defaults.string(forKey: "currentDisplayMode"),
           let mode = DisplayMode(rawValue: rawValue) {
            currentDisplayMode = mode
        }
        
        // 加载监控间隔
        if let interval = defaults.object(forKey: "currentMonitoringInterval") as? TimeInterval {
            currentMonitoringInterval = interval
        }
        
        // 加载上次选择的服务
        if let savedServiceName = defaults.string(forKey: "lastSelectedService") {
            if let savedEndpoint = ServiceManager.shared.endpoints.first(where: { $0.name == savedServiceName }) {
                currentEndpoint = savedEndpoint
            }
        }
    }
    
    /// 将当前模式和服务写入用户偏好
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(currentDisplayMode.rawValue, forKey: "currentDisplayMode")
        defaults.set(currentMonitoringInterval, forKey: "currentMonitoringInterval")
        
        if let endpoint = currentEndpoint {
            defaults.set(endpoint.name, forKey: "lastSelectedService")
        }
    }
    
    // MARK: - 服务管理
    
    /// 切换服务端点并立即开始延迟监控
    private func switchToEndpoint(_ endpoint: ServiceEndpoint) {
        currentEndpoint = endpoint
        monitor.startMonitoring(endpoint)
        updateCombinedDisplay()
        saveSettings()  // 保存服务选择
    }
    
    // MARK: - 显示更新
    
    /// 汇总当前需要显示的文本并更新到状态栏
    private func updateCombinedDisplay() {
        let displayText = createDisplayText()
        let statusIcon = createStatusIcon()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let button = self.statusBarItem?.button {
                button.title = displayText
                button.image = statusIcon
                
                // 设置工具提示
                button.toolTip = self.createTooltip()
            }
        }
    }
    
    /// 创建状态图标
    private func createStatusIcon() -> NSImage? {
        if let error = lastError {
            // 有错误时显示警告图标
            return NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Error")
        } else if isHealthy {
            // 健康状态显示检查图标
            return NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Healthy")
        } else {
            // 未知状态显示问号图标
            return NSImage(systemSymbolName: "questionmark.circle", accessibilityDescription: "Unknown")
        }
    }
    
    /// 创建工具提示
    private func createTooltip() -> String {
        var tooltip = "Moni - Network Monitor\n"
        
        switch currentDisplayMode {
        case .serviceLatency:
            if let endpoint = currentEndpoint {
                tooltip += "Service: \(endpoint.name)\n"
                tooltip += "Host: \(endpoint.host):\(endpoint.port)\n"
                tooltip += "Latency: \(currentLatency)\n"
            } else {
                tooltip += "No service selected\n"
            }
        case .networkSpeed:
            tooltip += "Download Speed: \(currentDownloadSpeed)\n"
        }
        
        tooltip += "Update Rate: \(Utilities.formatInterval(currentMonitoringInterval))\n"
        
        if let error = lastError {
            tooltip += "Status: Error - \(error.localizedDescription)"
        } else {
            tooltip += "Status: Healthy"
        }
        
        return tooltip
    }
    
    /// 创建显示文本
    private func createDisplayText() -> String {
        switch currentDisplayMode {
        case .serviceLatency:
            let serviceName = currentEndpoint?.name ?? AppConstants.defaultValue
            return "\(serviceName): \(currentLatency)"
        case .networkSpeed:
            return "↓\(currentDownloadSpeed)"
        }
    }
    
    /// 将速度格式化为 MB/s，保留两位小数
    private func formatSpeed(_ speed: Double) -> String {
        return String(format: "%.2fMB/s", speed)
    }
    
    // MARK: - MonitorLatencyDelegate
    
    /// 延迟更新回调（毫秒，0 位小数）
    func monitor(_ monitor: MonitorLatency, didUpdateLatency latency: TimeInterval, for endpoint: ServiceEndpoint) {
        let latencyMs = latency * 1000
        currentLatency = String(format: "%.0fms", latencyMs)
        lastError = nil
        isHealthy = true
        updateCombinedDisplay()
    }
    
    func monitor(_ monitor: MonitorLatency, didFailWithError error: MonitorError, for endpoint: ServiceEndpoint) {
        currentLatency = AppConstants.errorMessage
        lastError = error
        isHealthy = false
        
        // 记录错误日志
        Utilities.logError(error, context: "LatencyMonitor", additionalInfo: "Endpoint: \(endpoint.name)")
        
        // 显示用户友好的错误信息
        showUserFriendlyError(error, for: endpoint)
        
        updateCombinedDisplay()
    }
    
    // MARK: - MonitorNetworkDelegate
    
    /// 下行网速更新（单位 MB/s，2 位小数）
    func networkStats(_ stats: MonitorNetwork, didUpdateDownloadSpeed speed: Double) {
        currentDownloadSpeed = formatSpeed(speed)
        lastError = nil
        isHealthy = true
        updateCombinedDisplay()
    }
    
    func networkStats(_ stats: MonitorNetwork, didFailWithError error: MonitorError) {
        currentDownloadSpeed = AppConstants.defaultValue
        lastError = error
        isHealthy = false
        
        // 记录错误日志
        Utilities.logError(error, context: "NetworkMonitor")
        
        // 显示用户友好的错误信息
        showUserFriendlyError(error, for: nil)
        
        updateCombinedDisplay()
    }
    
    // MARK: - 错误处理
    
    /// 显示用户友好的错误信息
    private func showUserFriendlyError(_ error: MonitorError, for endpoint: ServiceEndpoint?) {
        let errorMessage = Utilities.userFriendlyErrorMessage(error)
        let title = "Monitoring Error"
        
        // 在状态栏显示错误提示
        DispatchQueue.main.async { [weak self] in
            // 可以在这里添加系统通知或其他用户友好的错误提示
            #if DEBUG
            print("[\(title)] \(errorMessage)")
            #endif
        }
    }
}