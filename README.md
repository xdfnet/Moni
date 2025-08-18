# Moni - AI 服务延迟监控工具

[![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-15.0+-blue.svg)](https://developer.apple.com/macos/)
[![Version](https://img.shields.io/badge/Version-1.06-green.svg)](https://github.com/your-repo/moni)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 项目简介

Moni 是一个轻量级的 macOS 菜单栏应用，专门用于实时监控 AI 服务（如 Claude、Gemini、DeepSeek、Kimi）的网络延迟和系统网络流量。通过直观的状态指示器和简化的连接状态管理，为用户提供可靠的网络监控体验。

## 主要特性

### 核心功能

- AI 服务延迟监控：实时测量 LLM 服务的网络延迟
- 网络流量统计：监控系统网络下载速度
- 菜单栏集成：轻量级设计，不占用桌面空间
- 可配置监控间隔：支持 0.5s、1s、2s、5s 多种频率

### 新增功能 (v1.06)

- 简化状态管理：连接成功/失败两种状态，无复杂重试逻辑
- 状态指示器：实时显示连接状态和健康度
- 配置管理系统：支持配置导入/导出和热重载
- 线程安全：完善的状态管理和资源管理
- 数据验证：网络数据有效性检查，异常数据自动重置
- 工具函数库：丰富的开发工具和调试支持

### 开发工具

- 模块化构建系统：Makefile 支持单独运行任何构建步骤
- 代码质量检查：自动化的代码规范检查脚本
- 统一注释规范：专业的代码文档标准
- 错误处理机制：完善的异常处理和恢复逻辑

## 快速开始

### 环境要求

- 操作系统：macOS 15.0 或更高版本
- 开发工具：Xcode 15.0 或更高版本
- 编程语言：Swift 5.0

### 安装和运行

#### 使用 Makefile（推荐）

```bash
# 克隆项目
git clone <repository-url>
cd Moni

# 完整构建（包含版本号递增）
make build

# 固定版本构建
make build-fixed

# 查看所有可用命令
make help
```

#### 使用 Xcode

```bash
# 打开项目
open Moni.xcodeproj

# 选择目标设备（macOS）
# 点击构建按钮或使用快捷键 Cmd+B
```

### 使用说明

1. 应用启动后会在菜单栏显示图标
2. 点击图标查看监控菜单
3. 选择 "View" → "LLM" 监控 AI 服务延迟
4. 选择 "View" → "Net" 监控网络流量
5. 通过 "Rate" 菜单调整监控频率

## 项目结构

```text
Moni/
├── Moni/                    # 主要源代码
│   ├── App.swift           # 应用入口点
│   ├── MenuBarController.swift  # 菜单栏控制器
│   ├── BaseMonitor.swift   # 基础监控类
│   ├── MonitorLatency.swift    # 延迟监控实现
│   ├── MonitorNetwork.swift    # 网络监控实现
│   ├── ServiceManager.swift    # 服务端点管理
│   ├── ConfigurationManager.swift # 配置管理
│   ├── SharedTypes.swift   # 共享类型定义
│   └── Utilities.swift     # 工具函数库
├── Scripts/                 # 构建和检查脚本
│   └── code_quality_check.sh # 代码质量检查
├── Docs/                    # 项目文档
└── Makefile                 # 构建自动化脚本
```

## 技术架构

### 设计模式

- 分层架构：清晰的功能分层和职责分离
- 代理模式：监控结果的回调通知
- 观察者模式：状态变化的实时更新
- 工厂模式：服务端点的统一管理

### 核心技术

- Swift 5.0：现代化的 Swift 语言特性
- SwiftUI：声明式用户界面框架
- Network.framework：高性能网络监控
- sysctl：系统级网络统计信息
- GCD：异步任务和线程管理

## 开发指南

### 代码规范

- 遵循 Swift API Design Guidelines
- 使用统一的注释风格
- 支持中文注释，便于理解
- 完整的错误处理和日志记录

### 构建系统

```bash
make help              # 查看所有可用命令
make quality-check     # 运行代码质量检查
make clean             # 清理构建文件
make test              # 运行测试
```

### 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交代码变更
4. 创建 Pull Request

## 版本历史

- v1.06 (2025-01-13): 简化状态管理、状态指示器、配置管理
- v1.05 (2025-01-13): 代码质量检查、注释规范
- v1.04 (2025-01-13): 基础监控类、网络监控、服务管理
- v1.03 (2025-01-13): 延迟监控、菜单栏控制器
- v1.02 (2025-01-12): 应用入口、基础架构
- v1.01 (2025-01-12): 项目初始化、构建工具
- v1.00 (2025-01-12): 初始版本发布

## 文档

- [架构文档](Docs/ARCHITECTURE.md) - 系统架构设计
- [开发指南](Docs/DEVELOPMENT.md) - 开发者文档
- [API 参考](Docs/API_REFERENCE.md) - 完整的 API 文档
- [功能特性](Docs/FEATURES.md) - 详细功能说明
- [注释规范](Docs/COMMENT_STANDARDS.md) - 代码注释标准
- [更新日志](Docs/CHANGELOG.md) - 版本变更记录

## 许可证

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。

## 联系方式

- 项目主页：[repository-url]
- 问题反馈：提交 GitHub Issue
- 功能建议：参与项目讨论

## 致谢

感谢所有为这个项目做出贡献的开发者和用户！

---

Moni - 让 AI 服务监控变得简单高效

---

Built with ❤️ using Swift and SwiftUI
