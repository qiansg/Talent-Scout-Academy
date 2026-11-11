#!/bin/bash
# 一键运行 Flutter（Web 模式，无需 iOS/Android 原生工程）
cd "$(dirname "$0")/.."
flutter pub get
flutter run -d chrome
