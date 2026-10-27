#!/usr/bin/env bash
# 安全装到手机：先拉一份手机上的数据库快照，再 adb install -r 覆盖安装。
# 绝不卸载 —— 覆盖失败就停住并打印原因（卸载会连 /data/data 一起删掉，账单全没）。
#
# 用法：
#   bash tool/install_phone.sh              # 自动选唯一在线设备
#   bash tool/install_phone.sh 94b6bc78     # 指定设备序列号
#   bash tool/install_phone.sh 94b6bc78 --no-build   # 用已有 APK
set -euo pipefail

PKG=com.xupurse.xupurse
cd "$(dirname "$0")/.."

DEVICE="${1:-}"
SKIP_BUILD="${2:-}"
ADB=(adb)
if [[ -n "$DEVICE" && "$DEVICE" != --* ]]; then
  ADB=(adb -s "$DEVICE")
elif [[ "$DEVICE" == --* ]]; then
  SKIP_BUILD="$DEVICE"; DEVICE=""
fi

if [[ -z "$DEVICE" ]]; then
  mapfile -t ONLINE < <("${ADB[@]}" devices | awk 'NR>1 && $2=="device"{print $1}')
  if [[ ${#ONLINE[@]} -ne 1 ]]; then
    echo "在线设备不是 1 台（${ONLINE[*]:-无}），请显式传序列号，例如：bash tool/install_phone.sh 94b6bc78" >&2
    exit 1
  fi
  ADB=(adb -s "${ONLINE[0]}")
fi
SERIAL="${ADB[2]}"

# 0) 设备必须在位：不在位就直接报错退出，不要装到别的设备上
if ! "${ADB[@]}" get-state >/dev/null 2>&1; then
  echo "设备 $SERIAL 不在线（adb devices 里看不到它），插好 USB 再试" >&2
  exit 1
fi

if [[ "$SKIP_BUILD" != "--no-build" ]]; then
  echo "==> flutter build apk --release"
  flutter build apk --release
fi
APK="build/app/outputs/flutter-apk/app-release.apk"
[[ -f "$APK" ]] || { echo "找不到 $APK" >&2; exit 1; }

# 1) 安装前快照：把手机上的数据库和定时备份原样拉到本地，出问题可直接回灌
SNAP="backups/phone/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$SNAP"
pull_file() { # $1=设备路径  $2=本地名
  local src="$1" out="$2" tmp="$SNAP/.tmp"
  # su 优先（root 设备），失败退回 run-as（debuggable 包）
  if "${ADB[@]}" exec-out "su -c 'cat \"$src\"'" > "$tmp" 2>/dev/null && [[ -s "$tmp" ]] \
     && [[ "$(head -c 15 "$tmp")" == "SQLite format 3" || "$out" == *.json ]]; then
    mv "$tmp" "$SNAP/$out"; return 0
  fi
  if "${ADB[@]}" exec-out "run-as $PKG cat \"$src\"" > "$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
    mv "$tmp" "$SNAP/$out"; return 0
  fi
  rm -f "$tmp"; return 1
}

FILES=$("${ADB[@]}" shell "su -c 'ls /data/data/$PKG/app_flutter' 2>/dev/null || run-as $PKG ls /data/data/$PKG/app_flutter" 2>/dev/null | tr -d '\r' || true)
GOT=0
for f in $FILES; do
  if pull_file "/data/data/$PKG/app_flutter/$f" "$f"; then
    echo "    快照: $f"
    GOT=$((GOT+1))
  fi
done
[[ $GOT -gt 0 ]] || echo "    （手机上没有可拉取的数据文件，跳过）" >&2

# 2) 覆盖安装：失败就退出，绝不 uninstall
echo "==> adb install -r $APK"
if ! OUT=$("${ADB[@]}" install -r "$APK" 2>&1); then
  echo "覆盖安装失败（未卸载任何东西，手机数据安全）：" >&2
  echo "$OUT" >&2
  case "$OUT" in
    *INSTALL_FAILED_UPDATE_INCOMPATIBLE*)
      echo ">> 签名不一致：手机上那版是用另一把 key 签的。换回同一把 key 的构建，或换一台设备再装，不要卸载。" >&2;;
    *INSTALL_FAILED_VERSION_DOWNGRADE*)
      echo ">> 版本号比手机上的低：先升 pubspec 的 +build 号再装。" >&2;;
  esac
  exit 1
fi
echo "    已覆盖安装，应用数据保留"

# 3) 启动
"${ADB[@]}" shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
echo "==> 完成（$SERIAL），本地快照目录：$SNAP"
