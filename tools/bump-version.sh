#!/usr/bin/env bash
#
# bump-version.sh — 版本号自增工具
#
# 用法：
#   bash tools/bump-version.sh patch    # 0.1.0 → 0.1.1，构建号 +1
#   bash tools/bump-version.sh minor    # 0.1.0 → 0.2.0，构建号 +1
#   bash tools/bump-version.sh major    # 0.1.0 → 1.0.0，构建号 +1
#   bash tools/bump-version.sh build    # 仅构建号 +1（同营销版本下迭代）
#
# 改 project.yml 的 MARKETING_VERSION + CURRENT_PROJECT_VERSION，
# 由 XcodeGen 注入到 Info.plist（CFBundleShortVersionString / CFBundleVersion），
# AppInfo.swift 运行时读出。
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="${1:-patch}"

# 读当前版本
CURRENT_MARKETING=$(grep '^    MARKETING_VERSION:' project.yml | sed -E 's/.*"([^"]+)".*/\1/')
CURRENT_BUILD=$(grep '^    CURRENT_PROJECT_VERSION:' project.yml | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$CURRENT_MARKETING" ] || [ -z "$CURRENT_BUILD" ]; then
  echo "✗ 无法从 project.yml 读出当前版本号"
  exit 1
fi

echo "当前版本: $CURRENT_MARKETING ($CURRENT_BUILD)"

# 拆分 major.minor.patch
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_MARKETING"

case "$MODE" in
  major)
    MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1)); PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  build)
    # 仅构建号自增，营销版本不动
    ;;
  *)
    echo "✗ 未知模式: $MODE（应为 major/minor/patch/build）"
    exit 1
    ;;
esac

NEW_MARKETING="$MAJOR.$MINOR.$PATCH"
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "新版本:   $NEW_MARKETING ($NEW_BUILD)"

# 跨平台 sed in-place（macOS 需要 -i ''，Linux/Git Bash 用 -i）
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE=(-i '')
else
  SED_INPLACE=(-i)
fi

sed "${SED_INPLACE[@]}" -E \
  "s/^(    MARKETING_VERSION:) \"[^\"]+\"/\1 \"$NEW_MARKETING\"/" project.yml
sed "${SED_INPLACE[@]}" -E \
  "s/^(    CURRENT_PROJECT_VERSION:) \"[^\"]+\"/\1 \"$NEW_BUILD\"/" project.yml

echo ""
echo "✓ project.yml 已更新"
echo ""
echo "下一步："
echo "  git add project.yml"
echo "  git commit -m \"chore: bump 版本到 $NEW_MARKETING ($NEW_BUILD)\""
echo "  在 Mac 端: xcodegen generate && 重新 build"
