#!/usr/bin/env bash
#
# 在 macOS 上把 design/*.svg 转成 Asset Catalog 需要的 PNG / PDF
# 依赖：
#   brew install librsvg          # 提供 rsvg-convert
#   或者用系统自带的 sips（精度稍差但无需安装）
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ICON_SVG="$ROOT/design/AppIcon.svg"
LAUNCH_SVG="$ROOT/design/LaunchLogo.svg"
ICONSET="$ROOT/RecallingMemories/Resources/Assets.xcassets/AppIcon.appiconset"
LAUNCH_IMAGESET="$ROOT/RecallingMemories/Resources/Assets.xcassets/LaunchLogo.imageset"

mkdir -p "$ICONSET" "$LAUNCH_IMAGESET"

# === 1. App Icon — 1024x1024 PNG ===========================================
echo "[1/2] 生成 AppIcon-1024.png"
if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -w 1024 -h 1024 "$ICON_SVG" -o "$ICONSET/AppIcon-1024.png"
elif command -v qlmanage >/dev/null 2>&1; then
  # 后备方案：用 macOS 的 qlmanage 渲染（精度低）
  TMP=$(mktemp -d)
  qlmanage -t -s 1024 -o "$TMP" "$ICON_SVG" >/dev/null
  mv "$TMP"/*.png "$ICONSET/AppIcon-1024.png"
  rmdir "$TMP" 2>/dev/null || true
else
  echo "ERROR: 需要 rsvg-convert 或 qlmanage。请运行：brew install librsvg" >&2
  exit 1
fi

# === 2. LaunchLogo — PDF 矢量 ==============================================
echo "[2/2] 生成 LaunchLogo.pdf"
if command -v rsvg-convert >/dev/null 2>&1; then
  rsvg-convert -f pdf "$LAUNCH_SVG" -o "$LAUNCH_IMAGESET/LaunchLogo.pdf"
else
  # 后备方案：先 PNG 再用 sips 转 PDF
  qlmanage -t -s 480 -o "$LAUNCH_IMAGESET" "$LAUNCH_SVG" >/dev/null
  mv "$LAUNCH_IMAGESET/LaunchLogo.svg.png" "$LAUNCH_IMAGESET/LaunchLogo.png"
  echo "  注：未生成矢量 PDF，使用 PNG 兜底（建议安装 librsvg）"
fi

echo "✓ 完成。Xcode 重新打开工程即可看到图标与启动屏。"
