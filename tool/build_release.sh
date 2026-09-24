#!/usr/bin/env bash
#
# Needham Capital  release 打包脚本
#
# 用法:
#   ./tool/build_release.sh          # 同时构建 APK 与 AAB
#   ./tool/build_release.sh apk      # 只构建 APK
#   ./tool/build_release.sh aab      # 只构建 AAB
#   ./tool/build_release.sh ipa      # 只构建 iOS ipa（需 macOS + Xcode 签名）
#
# 说明:
#   - Dart 层混淆: --obfuscate --split-debug-info=build/symbols
#     注: Dart 注释与源码文本只存在于 debug 包（kernel_blob），release 的 AOT
#     快照本就不含注释；这个脚本保证的是"符号名一定被混淆"，并在构建后校验。
#   - Android 原生层: R8 已由 android/app/build.gradle.kts 开启
#   - 不要让 IDE / 手敲 flutter build 直接出包：漏掉 --obfuscate 就会把
#     Dart 类名与方法名留在产物里，这个脚本会在构建后把它拦下来。
#   - build/symbols 与 build/app/outputs/mapping/release/mapping.txt 用于
#     崩溃堆栈还原，发布后请妥善备份，勿删。
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
  apk|aab|ipa|all) ;;
  *)
    echo "错误: 未知构建类型 '$BUILD_TYPE'（可用: apk / aab / ipa / all）" >&2
    exit 1
    ;;
esac

# 混淆自检：这些名字在代码里只作为 Dart 符号出现（没有任何地方把它们写成
# 字符串），所以一旦在产物里搜到，就说明这次构建没有走 --obfuscate。
verify_obfuscated() {
  local artifact="$1"
  if [ ! -f "$artifact" ]; then
    echo "错误: 找不到产物 $artifact" >&2
    exit 1
  fi
  python3 - "$artifact" <<'PY'
import sys
import zipfile

CANARIES = [
    b'_fetchOnce',
    b'_openLedger',
    b'_SplashScreenState',
    b'AlertRuleCodec',
    b'PortfolioScreen',
]

path = sys.argv[1]
with zipfile.ZipFile(path) as archive:
    # Android APK: lib/<abi>/libapp.so。Android AAB: base/lib/<abi>/libapp.so。
    # iOS: Payload/Runner.app/Frameworks/App.framework/App。
    # 这里只按后缀匹配，别写成 startswith('lib/')，否则 AAB 会匹配不到而
    # 静默跳过自检（等于没查）。
    slices = [
        name
        for name in archive.namelist()
        if name.endswith('libapp.so') or name.endswith('App.framework/App')
    ]
    if not slices:
        print(f'  警告: {path} 里没有找到 libapp.so，跳过混淆自检', file=sys.stderr)
        sys.exit(0)
    hits = {}
    for name in slices:
        data = archive.read(name)
        for canary in CANARIES:
            if canary in data:
                hits.setdefault(canary.decode(), []).append(name)

if hits:
    print(f'  混淆自检未通过: {path}', file=sys.stderr)
    for canary, where in sorted(hits.items()):
        print(f'    - 仍是明文符号: {canary} （{", ".join(where)}）', file=sys.stderr)
    print(
        '    -> 这次构建没有带 --obfuscate，请用本脚本打包。',
        file=sys.stderr,
    )
    sys.exit(1)

print(f'  混淆自检通过: {path}（{len(slices)} 个 libapp.so，无明文 Dart 符号）')
PY
}

if [ "$BUILD_TYPE" = "apk" ] || [ "$BUILD_TYPE" = "all" ]; then
    echo "==> 构建 release APK（Dart 混淆 + R8）..."
    "$FLUTTER" build apk --release \
      --obfuscate \
      --split-debug-info="$SYMBOL_DIR"
    verify_obfuscated "build/app/outputs/flutter-apk/app-release.apk"
fi

if [ "$BUILD_TYPE" = "aab" ] || [ "$BUILD_TYPE" = "all" ]; then
    echo "==> 构建 release AAB（Dart 混淆 + R8，用于 Google Play 上架）..."
    "$FLUTTER" build appbundle --release \
      --obfuscate \
      --split-debug-info="$SYMBOL_DIR"
    verify_obfuscated "build/app/outputs/bundle/release/app-release.aab"
fi

if [ "$BUILD_TYPE" = "ipa" ]; then
    echo "==> 构建 release ipa（Dart 混淆）..."
    "$FLUTTER" build ipa --release \
      --obfuscate \
      --split-debug-info="$SYMBOL_DIR"
    if compgen -G "build/ios/ipa/*.ipa" > /dev/null; then
        for ipa in build/ios/ipa/*.ipa; do
            verify_obfuscated "$ipa"
        done
    else
        echo "错误: 没有找到 build/ios/ipa/*.ipa，构建可能未产出 ipa。" >&2
        exit 1
    fi
fi

echo
echo "构建完成。产物:"
ls -lh \
  build/app/outputs/flutter-apk/app-release.apk \
  build/app/outputs/bundle/release/app-release.aab \
  build/ios/ipa/*.ipa 2>/dev/null || true
echo
echo "重要: 请备份 $SYMBOL_DIR 与 build/app/outputs/mapping/release/mapping.txt，"
echo "      崩溃日志里的混淆符号（Dart 与 Android 各一份）需要它们来还原。"
