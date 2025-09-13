#!/bin/bash

# --- Flutter SDKのインストール ---
# ユーザーが書き込み可能な /workspaces/ ディレクトリにインストール先を変更
git clone https://github.com/flutter/flutter.git --depth 1 /workspaces/flutter

# Flutterコマンドにパスを通す (新しいパスに変更)
echo 'export PATH="$PATH:/workspaces/flutter/bin"' >> ~/.bashrc
# すぐに使えるように現在のセッションでもパスを有効化
export PATH="$PATH:/workspaces/flutter/bin"

# Flutterのセットアップ（Doctorで確認）
flutter precache
flutter doctor

# --- Amplify CLIのインストール ---
npm install -g @aws-amplify/cli

echo "✅ Post-create script finished successfully!"