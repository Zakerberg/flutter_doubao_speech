# Doubao Speech Plugin

[![pub version](https://img.shields.io/pub/v/doubao_speech.svg)](https://pub.dev/packages/doubao_speech)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

一个基于 **豆包实时语音大模型** 开发的 Flutter 插件，提供跨平台（Android / iOS）的语音交互能力。

---

## 📖 简介

本插件封装了豆包实时语音大模型的原生 SDK，让你可以在 Flutter 应用中快速集成：

- 实时语音识别
- 流式语音合成
- 低延迟对话交互

---

## ✨ 特性

- ✅ 支持 Android + iOS
- ✅ 实时语音识别
- ✅ 流式 TTS 返回
- ✅ 简单易用的 Dart API
- ✅ 基于 EventChannel 的高效通信

---

## 🚀 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  doubao_speech: ^0.0.1

🎯 使用示例


📂 项目结构
text
doubao_speech/
├── lib/                # Dart 公共接口
├── android/            # Android 原生实现
├── ios/                # iOS 原生实现
├── example/            # 示例项目
├── test/               # 单元测试
├── pubspec.yaml
└── README.md


📄 许可证
本项目基于 MIT License 开源，详见 LICENSE 文件。

🔗 相关链接 + 🤝 参与贡献
[端到端Android SDK 接口文档]（https://www.volcengine.com/docs/6561/1597643?lang=zh）
[端到端iOS SDK 接口文档](https://www.volcengine.com/docs/6561/1597646?lang=zh)

⚠️ 注意事项:
1. 插件目前仅支持 Android 和 iOS, 需要联网使用,请遵守豆包大模型的使用条款.
2. 豆包底层采用的是透传模式, 所以没有语音播报完成的回调,如有这方面需求,请谨慎使用.
