# Glint

一句话简介：macOS 26+ 原生截屏工具——Liquid Glass 设计、智能选区、原地标注、贴图钉屏、OCR、取色、历史记录，菜单栏常驻、单键唤起。

## 功能

- **截图**：F6 一键唤起，冻结帧选区（AX 元素/窗口/全屏三档智能选区，Space 切换，单击选中，拖拽自由框选，方向键像素微调）
- **标注**：矩形/椭圆/箭头/画笔/荧光笔/文字/序号/马赛克/高斯模糊，⌘Z/⇧⌘Z 撤销重做
- **出口**：Enter 复制（可直接 ⌘V）、保存 PNG、贴图钉屏、OCR 文字识别（中英）
- **贴图**：F7 钉剪贴板图片；滚轮缩放、⌥滚轮透明度、双击缩略图、右键菜单、鼠标穿透、跨 Space
- **取色**：C 键取色模式，单击复制 HEX
- **历史**：最近 20 张（可调），菜单栏面板复制/重钉/访达显示

## 构建

前置：Xcode 26+（本机为 Xcode-beta 时用 DEVELOPER_DIR 前缀）、XcodeGen（brew install xcodegen）

```bash
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcodebuild -project Glint.xcodeproj -scheme Glint -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/Glint.app
```

纯逻辑单元测试：`cd GlintKit && swift test`

## 权限

- **屏幕录制**（必需）：首启引导窗申请，授权后重启 App
- **辅助功能**（可选）：开启后智能选区可识别 UI 元素；未开启降级为窗口级选区

## 默认快捷键

| 按键 | 功能 |
|------|------|
| F6 | 唤起截图 |
| F7 | 钉剪贴板图片 |
| Enter | 复制截图并退出 |
| Esc | 取消截图 / 关闭贴图 |
| Space | 选区三档切换（元素 → 窗口 → 全屏） |
| C | 取色模式 |
| 方向键 | 微调选区（Shift 键 ×10 像素） |
| ⌘Z / ⇧⌘Z | 撤销 / 重做 |

## 文档

设计文档与实现计划位于 Obsidian `07-Ideas/glint/`（不在本仓库内）。
