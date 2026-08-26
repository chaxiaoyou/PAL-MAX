#!/usr/bin/env bash
#
# PAL MAX release 打包脚本
#
# 用法:
#   ./tool/build_release.sh          # 同时构建 APK 与 AAB
#   ./tool/build_release.sh apk      # 只构建 APK
#   ./tool/build_release.sh aab      # 只构建 AAB
#
# 说明:
#   - Dart 层混淆: --obfuscate --split-debug-info=build/symbols
#   - Android 原生层: R8 已由 android/app/build.gradle.kts 开启
#   - build/symbols 目录用于崩溃堆栈还原，发布后请妥善备份，勿删。
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v flutter >/dev/null 2>&1; then
  FLUTTER="flutter"
elif [ -x "$HOME/flutter/bin/flutter" ]; then
  FLUTTER="$HOME/flutter/bin/flutter"
else
  echo "错误: 未找到 flutter，请先安装或将其加入 PATH。" >&2
  exit 1
fi

SYMBOL_DIR="build/symbols"
BUILD_TYPE="${1:-all}"

case "$BUILD_TYPE" in
  apk|aab|all) ;;
  *)
    echo "错误: 未知构建类型 '$BUILD_TYPE'（可用: apk / aab / all）" >&2
    exit 1
    ;;
esac

if [ "$BUILD_TYPE" = "apk" ] || [ "$BUILD_TYPE" = "all" ]; then
    echo "==> 构建 release APK（Dart 混淆 + R8）..."
    "$FLUTTER" build apk --release \
      --obfuscate \
      --split-debug-info="$SYMBOL_DIR"
fi

if [ "$BUILD_TYPE" = "aab" ] || [ "$BUILD_TYPE" = "all" ]; then
    echo "==> 构建 release AAB（Dart 混淆 + R8，用于 Google Play 上架）..."
    "$FLUTTER" build appbundle --release \
      --obfuscate \
      --split-debug-info="$SYMBOL_DIR"
fi

echo
echo "构建完成。产物:"
ls -lh build/app/outputs/flutter-apk/app-release.apk build/app/outputs/bundle/release/app-release.aab 2>/dev/null || true
echo
echo "重要: 请备份 $SYMBOL_DIR 目录，崩溃日志中的混淆符号需要它来还原。"
