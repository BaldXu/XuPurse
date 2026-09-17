# 部署流程

> 状态：🚧 规划中。XuPurse 是本地优先应用（无服务端），部署主要分三端产物构建与发布。以下为推荐流程。

## 1. 部署总览

| 平台 | 产物 | 发布渠道 | 数据存储 |
|------|------|---------|---------|
| Web | 静态文件（`build/web`） | Cloudflare Pages / Vercel / GitHub Pages / Nginx | 浏览器 IndexedDB |
| Android | APK / AAB | 应用商店 / 侧载 | 本地 SQLite |
| iOS | IPA | App Store（TestFlight） | 本地 SQLite |

## 2. 通用准备

```bash
# 1. 版本号统一管理
#    在 pubspec.yaml 中维护 version: 1.0.0+1

# 2. 先跑质量门禁
flutter analyze        # 静态分析 0 error
flutter test           # 测试通过

# 3. 更新 CHANGELOG（见 docs/changelog.md）
```

## 3. Web 部署

### 3.1 构建

```bash
flutter build web --release
# 产物位于 build/web/
```

### 3.2 静态托管配置要点

| 平台 | 配置 |
|------|------|
| Cloudflare Pages | 构建命令 `flutter build web --release`，输出目录 `build/web` |
| Vercel | 同上 |
| GitHub Pages | 需在仓库设置开启 Pages，推送 `build/web` 内容 |
| Nginx | `root /path/to/build/web;` + 单页应用路由回退 |

### 3.3 注意事项

- **PWA**：若启用 Service Worker，注意避免缓存旧版本数据（版本变更后提示刷新）。
- **SQLite WASM**：Web 端读取第三方 `.db` 依赖 WASM 文件，**必须确认服务器返回正确的 `application/wasm` MIME 类型**，否则报 "wasm magic word" 错误。
- **浏览器存储**：IndexedDB 容量有浏览器配额限制（通常数百 MB~GB），单账本数据量大时注意。

## 4. Android 部署

### 4.1 签名配置

```bash
# 生成签名密钥（仅首次）
keytool -genkey -v -keystore xupurse-release.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias xupurse

# 在 android/key.properties 配置（勿提交到 git）：
# storePassword=***
# keyPassword=***
# keyAlias=xupurse
# storeFile=../xupurse-release.jks
```

### 4.2 构建

```bash
flutter build apk --release                 # 通用 APK
flutter build appbundle --release           # AAB（上架 Google Play 推荐）
```

产物位置：`build/app/outputs/flutter-apk/` 与 `build/app/outputs/bundle/`。

### 4.3 上架前检查

- [ ] `android/app/build.gradle` 中 `applicationId` 与签名一致
- [ ] 版本号递增
- [ ] 隐私政策（涉及本地数据、权限说明）
- [ ] 图标与启动图（`flutter_launcher_icons`）

## 5. iOS 部署

> 仅 macOS 可构建，需要 Apple Developer 账号。

```bash
flutter build ios --release
# 或用 Xcode 打开 ios/Runner.xcworkspace 配置签名后 Archive
```

上架流程：

1. Xcode 打开工程 → 配置 Team / Bundle Identifier。
2. Product → Archive → Distribute App。
3. TestFlight 内测 → App Store 审核。

注意事项：

- 首次需要 `sudo xcodebuild -runFirstLaunch` 与 Xcode 命令行工具。
- 数据库文件默认写入应用沙盒（`Application Support`），卸载会丢失，如需跨设备恢复需配合导出备份。
- iOS 不支持在 WebView 中读取任意目录文件，第三方 `.db` 通过「文件 App」导入（`UIDocumentPicker`）。

## 6. 数据备份与迁移

虽然应用本地自持数据，建议提供：

| 能力 | 说明 |
|------|------|
| 导出备份 | JSON 全量导出（账单 + meta），压缩后下载/分享 |
| 导入备份 | 恢复备份（支持覆盖模式） |
| 第三方导入 | 一木 / 昼虎 / 钱迹 `.db` 直接导入 |

备份文件格式（对齐上一代 `ExportedJSON`）：

```json
{
  "items": [ /* 全量账单 */ ],
  "meta": { /* GlobalMeta 全量 */ }
}
```

## 7. 发布检查清单（通用）

- [ ] `flutter analyze` 无错误
- [ ] 单元测试通过（金额换算、导入映射、余额计算）
- [ ] 三端手动冒烟：记账 → 转账 → 调账 → 趋势 → 导入预览
- [ ] 深色模式 / 多语言切换正常
- [ ] 大账本数据（>10 万条账单）分页与趋势性能可接受
- [ ] 更新 `docs/changelog.md`
