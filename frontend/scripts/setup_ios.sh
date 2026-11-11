#!/bin/bash
# 自动生成 Xcode project
echo "初始化 iOS Xcode 工程..."
cd "$(dirname "$0")/.."
flutter create . --platforms=ios,android --org com.starexplorer --project-name star_explorer
echo "完成！"
