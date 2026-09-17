# 开发环境配置指南

> 状态：🚧 规划中。本指南面向从 0 开始的 Flutter 三端项目（Web / Android / iOS）。项目尚未初始化，以下为推荐的初始化步骤与常用命令。

## 1. 环境要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| Flutter SDK | 稳定版（≥3.x） | `flutter --version` 确认 |
| Dart SDK | 随 Flutter 自带 | - |
| Android Studio | 最新稳定版 | Android 构建 + 模拟器 |
| Xcode | 最新稳定版（macOS） | iOS 构建（仅 macOS 可用） |
| Chrome | 最新版 | Web 调试 |
| VS Code / Cursor | 任意 | 推荐安装 Flutter / Dart 插件 |

> 上一代项目为 React（Node + pnpm），与本项目无关；本指南只针对 Flutter。

## 2. 环境安装

### 2.1 安装 Flutter（macOS）

```bash
# 方式一：git 克隆（推荐，便于切换版本）
git clone https://github.com/flutter/flutter.git -b stable ~/development/flutter

# 方式二：Homebrew
brew install --cask flutter

# 配置 PATH（写入 ~/.zshrc）
export PATH="$PATH:$HOME/development/flutter/bin"

# 验证
flutter doctor
```

`flutter doctor` 输出应覆盖：

- Flutter 本体 ✅
- Android toolchain（Android SDK + 许可证）✅
- Xcode / iOS toolchain ✅
- Chrome（Web）✅
- VS Code 插件 ✅

### 2.2 常见修复

```bash
flutter doctor --android-licenses   # 接受 Android 许可证
open -a "Android Studio"            # 首次启动安装 SDK 组件
sudo xcodebuild -runFirstLaunch     # Xcode 首次运行
```

## 3. 项目初始化

```bash
# 在 XuPurse 根目录创建 Flutter 工程（含三端平台目录）
flutter create . --project-name xupurse --org com.xupurse \
    --platforms=android,ios,web

# 检查格式
dart format --set-exit-if-changed .

# 运行静态分析
flutter analyze

# 运行测试
flutter test
```

### 3.1 推荐依赖（按需引入）

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter_riverpod: ^2.5.0        # 状态管理
  drift: ^2.0.0                   # 本地数据库
  drift_flutter: ^0.1.0           # 跨端数据库（Web 走 IndexedDB）
  path_provider: ^2.1.0           # 文件路径（Android/iOS）
  fl_chart: ^0.68.0               # 图表
  intl: ^0.19.0                   # 国际化/日期
  uuid: ^4.0.0                    # ID 生成
  shared_preferences: ^2.2.0      # 轻量偏好（主题、语言）
  archive: ^3.0.0                 # 备份压缩
```

## 4. 运行命令

```bash
flutter pub get            # 安装依赖

flutter run -d chrome      # Web 调试
flutter run -d android     # Android 真机/模拟器
flutter run -d ios         # iOS 模拟器（macOS）

flutter analyze            # 静态分析
flutter test               # 单元测试
flutter build web          # 构建 Web
flutter build apk          # 构建 Android APK
```

## 5. 数据库与迁移规范

使用 drift（生成式 ORM），约定：

1. 所有表定义在 `lib/data/database/tables/` 下。
2. 新增字段使用 **Schema Migration**（`MigrationStrategy`），禁止删库重建。
3. 每个账本对应独立数据库文件 `book-<id>.db`，通过运行时打开不同数据库名实现。

> 上一代教训：Zustand persist 缺 migrate 导致结构变更即白屏。Flutter 版必须从一开始就建立迁移机制。

## 6. 多语言（i18n）

- 词条文件放 `lib/l10n/`（`.arb`），启用 `flutter gen-l10n`。
- 维护约束：
  - 各语言词条**数量必须一致**（zh / en）。
  - 原词条默认由翻译公司维护，**不要直接修改原词条**；需改文案时新增词条（原 key + `V2`/`V3` 后缀）并追加在文件底部。
  - 占位符统一 `{placeholder}` 语法，占位符内部不允许翻译。

## 7. 调试技巧

| 场景 | 方法 |
|------|------|
| 数据库内容检查 | Android Studio → App Inspection → Database Inspector |
| Web IndexedDB | DevTools → Application → IndexedDB |
| 网络（局域网同步） | DevTools → Network |
| 性能 | `flutter run --profile` / DevTools Performance |
| 打印 | `debugPrint()`（生产环境自动丢弃） |

## 8. 代码生成

drift 等需要 codegen 的依赖：

```bash
dart run build_runner build --delete-conflicting-outputs
```

> 修改表结构或 `_$Xxx` 生成类相关代码后必须重跑上述命令。
