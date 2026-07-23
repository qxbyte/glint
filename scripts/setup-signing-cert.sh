#!/usr/bin/env bash
# 创建并导入 Glint 本机签名用的自签名代码签名证书（仅需运行一次）。
#
# 该证书给 Glint 一个稳定的代码签名身份，使 macOS TCC 屏幕录制/辅助功能授权
# 能跨重建保留（详见 scripts/install.sh 顶部说明）。证书不进受信任根，也无需
# sudo —— codesign 仍可用它签名，本机 TCC 也认它的指纹。
set -euo pipefail

IDENTITY="Glint Dev Signing"
if security find-identity -v | grep -q "$IDENTITY"; then
  echo "✓ 证书「$IDENTITY」已存在，无需重复创建。"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

echo "→ 生成自签名代码签名证书…"
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 3650 -nodes \
  -subj "/CN=$IDENTITY" \
  -addext "extendedKeyUsage=codeSigning" \
  -addext "keyUsage=digitalSignature" \
  -addext "basicConstraints=critical,CA:false" >/dev/null 2>&1

# openssl 3 默认算法与钥匙串不兼容，必须 -legacy
openssl pkcs12 -export -legacy -out glint.p12 -inkey key.pem -in cert.pem \
  -passout pass:glintdev -name "$IDENTITY" >/dev/null 2>&1

echo "→ 导入登录钥匙串…"
security import glint.p12 -k ~/Library/Keychains/login.keychain-db -P glintdev -T /usr/bin/codesign

echo "✓ 完成。现在可运行 scripts/install.sh 构建安装。"
