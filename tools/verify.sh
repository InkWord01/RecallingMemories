#!/usr/bin/env bash
#
# verify.sh — 仓库一致性自检（在 VS Code 里能跑的部分）
#
# 检查项：
#   1. project.yml YAML 合法
#   2. Asset Catalog Contents.json 合法
#   3. design/*.svg 格式合法
#   4. tools/*.sh shellcheck（若装了）
#   5. AppInfo.author 包含 "zizhi"
#   6. ProfileView 已用 AppInfo.fullVersion 而非硬编码版本号
#   7. project.yml 已用 $(MARKETING_VERSION) 变量
#
# 用法：bash tools/verify.sh
#

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0

ok()   { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }

echo "▸ 校验 project.yml"
PY_BIN=""
if command -v python >/dev/null 2>&1; then PY_BIN=python
elif command -v python3 >/dev/null 2>&1; then PY_BIN=python3
fi

if [ -n "$PY_BIN" ] && $PY_BIN -c "import yaml" 2>/dev/null; then
  if $PY_BIN -c "import yaml; yaml.safe_load(open('project.yml'))" 2>/dev/null; then
    ok "project.yml 语法合法"
  else
    fail "project.yml YAML 错误"
  fi
else
  # 退化检查：缩进 / 大括号匹配的极简校验
  if grep -E "^[a-zA-Z]" project.yml >/dev/null 2>&1; then
    echo "  ⚠ 未装 pyyaml（pip install pyyaml），跳过严格校验"
    ok "project.yml 文件可读（粗校）"
  else
    fail "project.yml 不可读"
  fi
fi

echo ""
echo "▸ 校验 Asset Catalog JSON"
if [ -n "$PY_BIN" ]; then
  JSON_OK=true
  while IFS= read -r -d '' jsonfile; do
    if ! $PY_BIN -c "import json; json.load(open(r'$jsonfile'))" 2>/dev/null; then
      fail "$jsonfile 解析失败"
      JSON_OK=false
    fi
  done < <(find RecallingMemories/Resources/Assets.xcassets -name "Contents.json" -print0 2>/dev/null)
  $JSON_OK && ok "所有 Contents.json 合法"
else
  echo "  ⚠ 未找到 python，跳过 JSON 校验"
fi

echo ""
echo "▸ 校验 SVG"
if command -v xmllint >/dev/null 2>&1; then
  if find design -name "*.svg" -print0 2>/dev/null | xargs -0 -n1 xmllint --noout 2>/dev/null; then
    ok "所有 SVG 格式合法"
  else
    fail "SVG 格式错误"
  fi
else
  echo "  ⚠ 未装 xmllint，跳过 SVG 校验"
fi

# AppIcon viewBox sanity check —— 必须 1024×1024
if grep -qE 'viewBox="0 0 1024 1024"' design/AppIcon.svg 2>/dev/null; then
  ok "AppIcon viewBox 为 1024×1024"
else
  fail "AppIcon viewBox 不是 1024×1024（iOS 17+ AppIconSet 要求）"
fi

echo ""
echo "▸ 校验 shell 脚本"
if command -v shellcheck >/dev/null 2>&1; then
  SC_OK=true
  while IFS= read -r -d '' f; do
    if ! shellcheck "$f" 2>/dev/null; then
      fail "shellcheck 失败：$f"
      SC_OK=false
    fi
  done < <(find tools -name "*.sh" -print0 2>/dev/null)
  $SC_OK && ok "所有 shell 脚本通过 shellcheck"
else
  echo "  ⚠ 未装 shellcheck，跳过"
fi

echo ""
echo "▸ 校验作者署名"
if grep -q 'zizhi' RecallingMemories/Shared/AppInfo.swift 2>/dev/null; then
  ok "AppInfo.author 已署名 zizhi"
else
  fail "AppInfo.author 未包含 zizhi"
fi

echo ""
echo "▸ 校验版本号集中化"
if grep -q 'AppInfo.fullVersion\|AppInfo.marketingVersion' RecallingMemories/Views/Profile/ProfileView.swift 2>/dev/null; then
  ok "ProfileView 用 AppInfo 取版本"
else
  fail "ProfileView 仍硬编码版本号"
fi

if grep -q 'MARKETING_VERSION' project.yml 2>/dev/null; then
  ok "project.yml 用 \$(MARKETING_VERSION) 变量"
else
  fail "project.yml 未用 MARKETING_VERSION 变量"
fi

# 防止误开倒车 —— 如果硬编码 0.1.0 出现在 ProfileView 视为回退
if grep -qE '"0\.[0-9]+\.[0-9]+"' RecallingMemories/Views/Profile/ProfileView.swift 2>/dev/null; then
  fail "ProfileView 又出现了硬编码版本号"
fi

echo ""
echo "═══════════════════════════════════════"
echo "  通过: $PASS    失败: $FAIL"
echo "═══════════════════════════════════════"

if [ $FAIL -gt 0 ]; then
  exit 1
fi
