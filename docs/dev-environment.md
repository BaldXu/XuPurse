# 开发环境配置指南

> 面向 Flutter 三端项目（Web / Android / iOS）。项目已初始化并进入开发期，本指南记录环境要求、常用命令与既有约定。

## 1. 环境要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| Flutter SDK | 稳定版（pubspec `sdk: ^3.9.2`） | `flutter --version` 确认 |
| Dart SDK | 随 Flutter 自带 | - |
| Android Studio | 最新稳定版 | Android 构建 + 模拟器 |
| Xcode | 最新稳定版（macOS） | iOS 构建（仅 macOS 可用） |
| Chrome | 最新版 | Web 调试 |
| VS Code / Cursor | 任意 | 推荐安装 Flutter / Dart 插件 |

## 2. 常用命令

```bash
flutter pub get            # 安装依赖
flutter run -d chrome      # Web 调试
flutter run -d android     # Android 真机/模拟器（真机 id 会变，用 `adb devices` 确认）
flutter analyze            # 静态分析（0 error 门槛）
flutter test               # 单元测试
flutter run --profile -t lib/main_profile.dart   # 真机性能采集（帧率基线）
flutter build web          # 构建 Web
flutter build apk          # 构建 Android APK
dart run build_runner build --delete-conflicting-outputs  # drift codegen
```

## 3. 依赖（pubspec.yaml 现有）

- **状态管理**：flutter_riverpod
- **数据库**：drift + drift_flutter + sqlite3 + sqlite3_flutter_libs（Web 走 IndexedDB/WASM）
- **图表**：fl_chart
- **图标**：colorful_iconify_flutter + flutter_svg（Twitter 表情包 / twemoji）
- **工具**：intl / uuid / path / path_provider / shared_preferences / file_picker / http / archive

## 4. 数据库与迁移规范

使用 drift（生成式 ORM），约定：

1. 表定义集中在 `lib/data/database/`（app_database / global_database / tables）。
2. 结构变更用 **Schema Migration**（`MigrationStrategy`），禁止删库重建。
3. 每个账本对应独立数据库文件 `book-<id>.db`，全局库存 `books`。
4. 修改表结构后重跑 codegen：`dart run build_runner build --delete-conflicting-outputs`。

> 上一代教训：Zustand persist 缺 migrate 导致结构变更即白屏。本项目从建立迁移机制开始。

## 5. 多语言（i18n）

- 词条文件放 `lib/l10n/`（`.arb`），启用 `flutter gen-l10n`。
- 维护约束：
  - 各语言词条**数量必须一致**（zh / en）。
  - 原词条默认由翻译公司维护，**不要直接修改**；需改文案时新增词条（原 key + `V2`/`V3` 后缀）并追加在文件底部。
  - 占位符统一 `{placeholder}` 语法，占位符内部不允许翻译。

## 6. 调试技巧

| 场景 | 方法 |
|------|------|
| 数据库内容检查 | Android Studio → App Inspection → Database Inspector |
| Web IndexedDB | DevTools → Application → IndexedDB |
| 性能 | `flutter run --profile` / DevTools Performance |
| 打印 | `debugPrint()`（生产环境自动丢弃） |
