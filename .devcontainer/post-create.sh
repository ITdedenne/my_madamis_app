#!/bin/bash

# --- Flutter SDKのインストール ---
echo "Cloning Flutter repository..."
git clone https://github.com/flutter/flutter.git --depth 1 /workspaces/flutter

# ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
# 【重要】安定版（stable）チャンネルに切り替える
echo "Switching to Flutter stable channel..."
cd /workspaces/flutter
git checkout stable
cd /workspaces/my_madamis_app
# ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

# Flutterコマンドにパスを通す
echo "Configuring Flutter PATH..."
echo 'export PATH="$PATH:/workspaces/flutter/bin"' >> ~/.bashrc
export PATH="$PATH:/workspaces/flutter/bin"

# Flutterのセットアップ（Doctorで確認）
echo "Running flutter doctor..."
flutter doctor

# --- Amplify CLIのインストール ---
echo "Installing Amplify CLI..."
npm install -g @aws-amplify/cli

echo "✅ Post-create script finished successfully!"