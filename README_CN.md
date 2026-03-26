# IP Switch

一款 macOS 菜单栏应用，用于快速切换网络接口的 IP 配置。基于 SwiftUI 构建，采用 Apple 毛玻璃设计风格。

[English](README.md) | 中文

## 功能特性

### 网络接口管理
- 自动检测所有网络接口（Wi-Fi、以太网、USB 网卡、雷雳接口等）
- 实时显示状态：IP 地址、子网掩码、路由器、DNS 服务器
- 支持 DHCP（自动获取）和手动 IP 配置
- 一键切换 DHCP 模式
- 热插拔检测 — 刷新即可发现新连接的网卡

### 配置方案
- 将当前接口设置保存为可复用的配置方案
- 创建自定义方案，指定 IP / 子网掩码 / 路由器 / DNS
- 提供 10 种图标供选择，方便视觉识别
- 从菜单栏一键应用配置方案
- 已应用的方案以绿色标签标识
- 支持编辑、删除，右键菜单快捷操作

### 菜单栏快速切换
- 原生 macOS 菜单栏下拉菜单，即点即用
- 一览所有接口状态
- 无需打开主窗口即可切换配置方案
- 快捷键：`⌘R` 刷新、`⌘,` 设置、`⌘Q` 退出

### 永久授权
- 通过 sudoers 规则实现一次性管理员密码设置
- 授权后，所有 IP 切换操作无需再次输入密码
- 可随时在设置侧边栏撤销授权
- 未授权时自动回退到逐次密码验证

### 双语界面
- 完整的中文和英文本地化支持
- 运行时切换语言，无需重启
- 语言偏好跨会话保持

### 智能 Dock 行为
- 默认作为菜单栏应用运行（不显示 Dock 图标）
- 打开设置窗口时 Dock 图标自动出现
- 关闭设置窗口后 Dock 图标自动隐藏

## 截图

| 主窗口 | 菜单栏 |
|:------:|:------:|
| NavigationSplitView 双栏布局 + 毛玻璃卡片 | 原生下拉菜单快速切换配置 |

## 系统要求

- macOS 26.0 或更高版本
- Xcode 26.0 或更高版本（从源码构建）

## 安装

### 从源码构建

```bash
git clone https://github.com/ryanhe919/IP-Switch.git
cd IP-Switch
open IP-Switch.xcodeproj
```

在 Xcode 中按 `⌘R` 编译运行。

### 首次使用

1. 启动应用 — 菜单栏出现图标
2. 点击菜单栏图标 → **设置** 打开主窗口
3. （可选）在侧边栏「权限管理」区域点击 **授予永久权限**，启用免密切换

## 项目架构

```
IP-Switch/
├── IP_SwitchApp.swift              # 应用入口、MenuBarExtra、Dock 行为控制
├── Models/
│   ├── NetworkInterface.swift      # 网络接口数据模型
│   └── IPProfile.swift             # IP 配置方案数据模型
├── Services/
│   ├── NetworkService.swift        # networksetup 命令、sudo/AppleScript 提权
│   └── LocalizationManager.swift   # 中英文运行时本地化
├── ViewModels/
│   └── NetworkViewModel.swift      # 业务逻辑、方案 CRUD、授权管理
├── Views/
│   ├── ContentView.swift           # 主窗口（NavigationSplitView）
│   ├── MenuBarView.swift           # 菜单栏下拉视图
│   ├── ProfileEditView.swift       # 方案创建/编辑表单
│   └── Components/
│       └── GlassCard.swift         # 毛玻璃 UI 组件
└── Assets.xcassets/                # 应用图标和颜色资源
```

### 关键设计决策

| 决策 | 原因 |
|------|------|
| `networksetup` CLI | Apple 官方网络配置工具，不使用私有 API |
| sudoers.d 规则 | 仅对 `networksetup` 免密，范围可控且可撤销 |
| AppleScript 回退 | 未安装 sudoers 时优雅降级 |
| `@Observable` 宏 | 现代 SwiftUI 状态管理（macOS 14+） |
| UserDefaults 持久化 | 轻量级的方案和偏好存储 |
| 无外部依赖 | 纯原生 Swift 实现，无 CocoaPods、SPM 或第三方库 |

## 工作原理

### 网络检测
应用通过 `networksetup -listallhardwareports` 发现所有接口，再分别用 `networksetup -getinfo <服务名>` 和 `networksetup -getdnsservers <服务名>` 获取当前配置信息。

### IP 配置
- **DHCP**：`sudo networksetup -setdhcp "<服务名>"`
- **手动 IP**：`sudo networksetup -setmanual "<服务名>" <IP> <子网掩码> <路由器>`
- **DNS**：`sudo networksetup -setdnsservers "<服务名>" <DNS1> <DNS2> ...`

### 授权机制
授予永久权限时，应用安装一条 sudoers 规则：
```
<用户名> ALL=(root) NOPASSWD: /usr/sbin/networksetup
```
该文件存放于 `/etc/sudoers.d/ip-switch`，权限为 `0440`。可随时通过应用撤销，或手动执行 `sudo rm /etc/sudoers.d/ip-switch` 移除。

## 许可证

本项目基于 MIT 许可证开源 — 详见 [LICENSE](LICENSE) 文件。

## 作者

**Yufan He** — [@ryanhe919](https://github.com/ryanhe919)
