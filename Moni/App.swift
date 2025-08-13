//
//  App.swift
//  Moni
//
//  Created by Moni Team
//  Copyright © 2025 Moni App. All rights reserved.
//
//  应用入口文件：负责应用生命周期管理
//
//  功能说明：
//  - 使用 SwiftUI 的 @main + App 协议作为入口
//  - 通过 AppDelegate 启动菜单栏管理器 MenuBarController
//  - 不创建主窗口，仅提供菜单栏应用形态
//

import SwiftUI

// MARK: - 主应用结构

@main
struct MoniApp: App {
    
    // MARK: - 属性
    
    /// 应用代理适配器
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - 场景构建
    
    var body: some Scene {
        // 不需要主窗口，仅保留设置入口（隐藏）
        Settings {
            EmptyView()
        }
    }
}

// MARK: - 应用代理

class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - 属性
    
    /// 菜单栏管理器实例
    var menuBarManager: MenuBarController?
    
    // MARK: - 应用生命周期
    
    /// 应用启动完成回调
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标，仅保留菜单栏图标
        NSApp.setActivationPolicy(.accessory)
        
        // 初始化菜单栏管理器（创建状态栏图标与菜单）
        menuBarManager = MenuBarController()
    }
    
    /// 应用即将退出回调
    func applicationWillTerminate(_ notification: Notification) {
        // 退出前清理资源（停止定时器、释放对象）
        menuBarManager?.cleanup()
    }
}