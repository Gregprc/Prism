# Prism

使用我的应用同样是对 [5KM Tech 的支持](https://5km.tech)：

<p align="center">
  <a href="https://zipic.app"><img src="https://5km.tech/products/zipic/icon.png" width="60" height="60" alt="Zipic" style="border-radius: 12px; margin: 4px;"></a>
  <a href="https://orchard.5km.tech"><img src="https://5km.tech/products/orchard/icon.png" width="60" height="60" alt="Orchard" style="border-radius: 12px; margin: 4px;"></a>
  <a href="https://apps.apple.com/cn/app/timego-clock/id6448658165?l=en-GB&mt=12"><img src="https://5km.tech/products/timego/icon.png" width="60" height="60" alt="TimeGo Clock" style="border-radius: 12px; margin: 4px;"></a>
  <a href="https://keygengo.5km.tech"><img src="https://5km.tech/products/keygengo/icon.png" width="60" height="60" alt="KeygenGo" style="border-radius: 12px; margin: 4px;"></a>
  <a href="https://hipixel.5km.tech"><img src="https://hipixel.5km.tech/_next/image?url=%2Fappicon.png&w=256&q=75" width="60" height="60" alt="HiPixel" style="border-radius: 12px; margin: 4px;"></a>
</p>

---

<p align="right">
  <a href="README.md">English</a> | <span>简体中文</span>
</p>

<p align="center">
  <a href="#-许可证">
    <img src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg" alt="许可证：AGPL v3" style="border-radius: 8px;">
  </a>
  <a href="https://developer.apple.com/swift">
    <img src="https://img.shields.io/badge/Swift-6.2-orange.svg" alt="Swift 6.2" style="border-radius: 8px;">
  </a>
  <a href="https://developer.apple.com/macos">
    <img src="https://img.shields.io/badge/Platform-macOS-lightgrey.svg" alt="平台：macOS" style="border-radius: 8px;">
  </a>
  <a href="https://developer.apple.com/macos">
    <img src="https://img.shields.io/badge/macOS-14.0%2B-brightgreen.svg" alt="macOS 14.0+" style="border-radius: 8px;">
  </a>
</p>

Prism 是一款 SwiftUI 打造的 macOS 菜单栏工具，用于统一管理兼容 Claude 的 API 服务，不论是官方模型提供方还是第三方 Anthropic 网关。项目最初只是为了验证大模型能否独立完成原生 macOS 工具的开发，绝大部分代码都由 AI 代理生成，人类只负责拼装与收尾。没想到原型意外好用，于是决定开源分享——也请大家在使用时尊重许可证。

### ✨ 功能亮点

- 🧱 管理多套 AI 提供商配置，支持类型化的环境变量与自定义图标
- 🔁 一键激活后写入 `.claude/settings.json`，在备份旧值的同时保留用户自定义键
- 🧠 预置多家 Claude 兼容服务模板（智谱、月之暗面、DeepSeek、MiniMax 等），也可快速创建自定义条目
- 🛡️ 自动生成配置备份，调试日志会对敏感 token 做遮罩处理
- 🔔 在菜单栏即可触发 Sparkle 检查更新
- 🎯 适合快速操作的键盘友好型迷你界面

### 🧭 架构速览

- `Prism/App/` —— 菜单栏入口、Popover 生命周期与 Sparkle 启动逻辑
- `ViewModels/` —— 通过 `@Observable` 管理提供商切换、配置同步与界面状态
- `Views/` 与 `Views/Components/` —— 管理列表、动画过渡与确认浮层等 SwiftUI 视图
- `Services/` —— 负责配置文件访问、导入同步以及提供商持久化
- `Models/` —— 环境变量类型、模板集合及 token 去重等共享模型
- `Extensions/` —— 复用的样式与渐变按钮扩展

### 🚀 快速上手

1. 克隆仓库并进入项目目录。
2. 使用 Xcode 16（Swift 6 工具链）或更新版本打开 `Prism.xcodeproj`。
3. 选择 `Prism` scheme，执行构建（`Command + B`）或使用命令行运行测试：

   ```bash
   xcodebuild -scheme Prism -configuration Debug test -destination 'platform=macOS'
   ```

4. 确认应用可以读写 `~/.claude/settings.json`。Prism 运行在无沙盒模式，请确保当前用户对该文件具有访问权限。

### 🔐 配置提示

- Prism 会直接修改 `.claude/settings.json`，请避免同时使用其他工具编辑该文件，以免覆盖写入。
- 每次写入都会生成备份，可在同目录下找到 `settings.json.backup` 以便回滚。
- 调试输出会对 `ANTHROPIC_AUTH_TOKEN` 等敏感字段进行加掩处理，提交 issue 或截图时也请继续隐藏密钥。

### 🤖 AI 主导的开发历程

Prism 的需求讨论、脚手架和大部分 Swift 代码均由自主运行的 AI 开发者完成。人工主要负责审查架构、验证文件系统访问路径，并在体验层做收尾。我们希望公开代码后，大家能帮助验证模型生成的实现细节，欢迎反馈任何边界问题或奇怪行为。

### 🌱 为什么开源？

Prism 原本是为了验证 GLM 4.6 等国产模型在真实编码场景下的表现。身边朋友体验后也想使用，我们才决定公开源码。还请遵守许可证，并把改进回馈给社区。


### 🤝 参与贡献

欢迎提交 Issue 或 PR：无论是修复 AI 生成的奇怪行为、补充新的代理模板，还是加强配置相关的测试用例。提交代码时请保持英文注释与约定的目录结构，并在推送前执行 `xcodebuild ... test`。提交即代表同意遵守 AGPLv3 许可。

### 🪪 许可证

Prism 以 GNU Affero General Public License v3.0 授权发布。您可以使用、修改并再分发该软件，但必须保持相同的许可证，并向使用者提供完整源代码访问。请务必保留许可声明，感谢你们共同维护 Prism 的开放性。
