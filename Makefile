#
#  Makefile
#  Moni
#
#  Created by Moni Team
#  Copyright © 2025 Moni App. All rights reserved.
#
#  Moni 项目构建工具
#
#  功能说明：
#  - 提供完整的项目构建流程
#  - 自动版本号递增和构建号生成
#  - 应用生命周期管理（关闭、构建、安装、启动）
#  - 支持固定版本构建模式
#  - 彩色终端输出和进度指示
#  - 控制台输出模式：通过修改 OUTPUT_MODE 变量控制构建输出
#    - 默认模式：空值（显示标准构建信息）
#    - 详细模式：-verbose（显示所有构建细节）
#    - 静默模式：-quiet（只显示警告和错误）
#    - 完全静默：> /dev/null 2>&1（隐藏所有输出）
#

# 项目基本信息
PROJECT_NAME = Moni
APP_NAME = Moni
SCHEME = Moni
CONFIGURATION = Release

# 构建路径配置
BUILD_DIR = ./build
PRODUCT_DIR = $(BUILD_DIR)/Build/Products/$(CONFIGURATION)
APP_BUNDLE = $(PRODUCT_DIR)/$(PROJECT_NAME).app

# 配置文件路径
SOURCE_INFO_PLIST = ./$(PROJECT_NAME)/Info.plist

# 输出模式配置
OUTPUT_MODE = > /dev/null 2>&1

# 颜色控制 - 支持 macOS 终端
# 检测是否支持颜色输出
ifeq ($(shell test -t 0 && echo 1),1)
    # 支持颜色
    GREEN = \033[0;32m
    YELLOW = \033[0;33m
    RED = \033[0;31m
    BLUE = \033[0;34m
    NC = \033[0m
    # 图标
    ICON_SUCCESS = ✓
    ICON_WARNING = ⚠️
    ICON_ERROR = ✗
    ICON_INFO = ℹ️
    ICON_STEP = 🔄
else
    # 不支持颜色时使用纯文本
    GREEN = 
    YELLOW = 
    RED = 
    BLUE = 
    NC = 
    ICON_SUCCESS = [OK]
    ICON_WARNING = [WARN]
    ICON_ERROR = [ERROR]
    ICON_INFO = [INFO]
    ICON_STEP = [STEP]
endif

.PHONY: build build-fixed step-clear step-close-app step-update-version step-build-app step-install-app step-cleanup step-open-app step-complete

# 清理控制台
step-clear:
	@clear # 清理控制台

# 第一步：检查并关闭运行中的应用
step-close-app:
	@echo "--------------------------------"
	@echo "$(BLUE)第一步：$(YELLOW)检查并关闭运行中的应用...$(NC)"
	@echo "--------------------------------"
	@if pgrep -f "/Applications/$(APP_NAME).app" > /dev/null; then \
		echo "  $(ICON_STEP) 发现运行中的$(APP_NAME)，正在关闭..."; \
		pkill -f "/Applications/$(APP_NAME).app" && sleep 1; \
		echo "$(GREEN)$(ICON_SUCCESS) 应用已关闭$(NC)"; \
	else \
		echo "$(GREEN)$(ICON_SUCCESS) 无运行中的应用实例$(NC)"; \
	fi

# 第二步：更新版本号
step-update-version:
	@echo "--------------------------------"
	@echo "$(BLUE)第二步：$(YELLOW)更新版本号...$(NC)"
	@echo "--------------------------------"
	@CURRENT_FULL_VERSION=$$(plutil -extract CFBundleShortVersionString raw "$(SOURCE_INFO_PLIST)" 2>/dev/null || echo "1.00"); \
	MAJOR=$$(echo $$CURRENT_FULL_VERSION | awk -F. '{print $$1}'); \
	MINOR=$$(echo $$CURRENT_FULL_VERSION | awk -F. '{print $$2}'); \
	NEW_MINOR=$$(($$MINOR + 1)); \
	NEW_VERSION="$${MAJOR}.$$(printf "%02d" $$NEW_MINOR)"; \
	BUILD_NUMBER=$$(date +%Y%m%d%H%M%S); \
	echo "$(GREEN)$(ICON_SUCCESS) 版本号已更新：$$CURRENT_FULL_VERSION → $$NEW_VERSION (Build: $$BUILD_NUMBER)$(NC)"; \
	echo "  正在更新 Info.plist 文件..."; \
	plutil -replace CFBundleShortVersionString -string "$$NEW_VERSION" "$(SOURCE_INFO_PLIST)"; \
	plutil -replace CFBundleVersion -string "$$BUILD_NUMBER" "$(SOURCE_INFO_PLIST)"; \
	echo "$(GREEN)$(ICON_SUCCESS) Info.plist 文件已更新$(NC)"; \
	echo "  正在更新 Xcode 项目文件..."; \
	sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $$NEW_VERSION;/g" "$(PROJECT_NAME).xcodeproj/project.pbxproj"; \
	sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = $$BUILD_NUMBER;/g" "$(PROJECT_NAME).xcodeproj/project.pbxproj"; \
	echo "$(GREEN)$(ICON_SUCCESS) Xcode 项目文件已更新$(NC)"

# 第三步：构建应用
step-build-app:
	@echo "--------------------------------"
	@echo "$(BLUE)第三步：$(YELLOW)构建 $(APP_NAME)...$(NC)"
	@echo "--------------------------------"
	@xcodebuild -project $(PROJECT_NAME).xcodeproj -scheme $(SCHEME) -configuration $(CONFIGURATION) -derivedDataPath $(BUILD_DIR) build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO $(OUTPUT_MODE)
	@if [ -d "$(APP_BUNDLE)" ]; then \
		echo "$(GREEN)$(ICON_SUCCESS) 构建成功$(NC)"; \
	else \
		echo "$(RED)$(ICON_ERROR) 构建失败$(NC)"; \
		exit 1; \
	fi

# 第四步：安装应用到 /Applications
step-install-app:
	@echo "--------------------------------"
	@echo "$(BLUE)第四步：$(YELLOW)安装应用到 /Applications...$(NC)"
	@echo "--------------------------------"
	@rm -rf "/Applications/$(APP_NAME).app"
	@cp -R "$(APP_BUNDLE)" "/Applications/$(APP_NAME).app"
	@if [ -d "/Applications/$(APP_NAME).app" ]; then \
		echo "$(GREEN)$(ICON_SUCCESS) 应用安装成功：/Applications/$(APP_NAME).app$(NC)"; \
	else \
		echo "$(RED)$(ICON_ERROR) 应用安装失败$(NC)"; \
		exit 1; \
	fi

# 第五步：清理构建文件
step-cleanup:
	@echo "--------------------------------"
	@echo "$(BLUE)第五步：$(YELLOW)清理构建文件...$(NC)"
	@echo "--------------------------------"
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)$(ICON_SUCCESS) 清理完成$(NC)"

# 第六步：打开应用
step-open-app:
	@echo "--------------------------------"
	@echo "$(BLUE)第六步：$(YELLOW)打开应用...$(NC)"
	@echo "--------------------------------"
	@open "/Applications/$(APP_NAME).app"

# 第七步：完成
step-complete:
	@echo "--------------------------------"
	@echo "$(BLUE)第七步：$(YELLOW)完成$(NC)"
	@echo "--------------------------------"

# 主构建流程（包含版本号递增）
build: step-clear step-close-app step-update-version step-build-app step-install-app step-cleanup step-open-app step-complete

# 固定版本构建流程（不递增版本号）
build-fixed: step-clear step-close-app step-build-app step-install-app step-cleanup step-open-app step-complete


