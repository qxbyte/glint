#!/usr/bin/env bash
# Glint 本机安装脚本：Release 构建 → 稳定证书签名 → 装入 /Applications
#
# 为什么要固定证书签名：macOS TCC（屏幕录制/辅助功能授权）按 App 的代码签名身份
# 记忆授权。ad-hoc 签名（"-"）没有稳定身份，每次重建 cdhash 变化都会让旧授权失效，
# 表现为"每次启动都要重新授权、且授权无效"。用一张固定的自签名证书签名后，
# designated requirement 锁定到该证书指纹，授权即可跨重建保留。
#
# 首次使用前需创建证书（仅一次）：scripts/setup-signing-cert.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
IDENTITY="Glint Dev Signing"
XCODE_DEV="${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}"

if ! security find-identity -v | grep -q "$IDENTITY"; then
  echo "✗ 找不到签名证书「$IDENTITY」。先运行：scripts/setup-signing-cert.sh" >&2
  exit 1
fi

cd "$REPO"
echo "→ 生成工程并构建 Release…"
xcodegen generate >/dev/null
DEVELOPER_DIR="$XCODE_DEV" xcodebuild -project Glint.xcodeproj -scheme Glint \
  -configuration Release -derivedDataPath build build >/dev/null

APP="build/Build/Products/Release/Glint.app"
echo "→ 用固定证书签名…"
codesign --force --deep --sign "$IDENTITY" "$APP"

echo "→ 安装到 /Applications…"
pkill -x Glint 2>/dev/null || true
rm -rf /Applications/Glint.app
cp -R "$APP" /Applications/

echo "→ 校验签名身份（应含 certificate leaf 指纹）…"
codesign -d --requirements - /Applications/Glint.app 2>&1 | grep designated || true

open /Applications/Glint.app
echo "✓ 完成。若这是首次用固定证书安装，请在系统设置里授权一次屏幕录制，之后重建不再需要重新授权。"
