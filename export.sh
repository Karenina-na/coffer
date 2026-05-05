#!/usr/bin/env bash
# export.sh — 打包 Coffer 项目（排除构建产物和缓存）
# 用法：bash export.sh [输出路径]
# 示例：bash export.sh ~/Desktop/coffer_export.zip

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
DEFAULT_OUT="$HOME/Desktop/coffer_${TIMESTAMP}.zip"
OUTPUT="${1:-$DEFAULT_OUT}"

# 排除列表
EXCLUDES=(
  "build/*"
  ".dart_tool/*"
  ".gradle/*"
  ".idea/*"
  "*.iml"
  "**/.DS_Store"
  ".DS_Store"
  "android/.gradle/*"
  "android/app/build/*"
  "android/build/*"
  "ios/.symlinks/*"
  "ios/Pods/*"
  "ios/build/*"
  "macos/.symlinks/*"
  "macos/Pods/*"
  ".flutter-plugins"
  ".flutter-plugins-dependencies"
)

# 构造 zip 排除参数
EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
  EXCLUDE_ARGS+=(-x "$pattern")
done

echo "▶ 打包项目：$PROJECT_DIR"
echo "▶ 输出文件：$OUTPUT"
echo ""

cd "$PROJECT_DIR"
zip -r "$OUTPUT" . "${EXCLUDE_ARGS[@]}" -q

SIZE=$(du -sh "$OUTPUT" | cut -f1)
echo "✓ 打包完成：$OUTPUT（$SIZE）"
