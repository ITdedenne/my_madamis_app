#!/bin/bash

# --- Flutter SDKのインストール ---
git clone https://github.com/flutter/flutter.git --depth 1 /usr/local/flutter
# Flutterコマンドにパスを通す
echo 'export PATH="$PATH:/usr/local/flutter/bin"' >> ~/.bashrc
# すぐに使えるように現在のセッションでもパスを有効化
export PATH="$PATH:/usr/local/flutter/bin"

# Flutterのセットアップ（Doctorで確認）
flutter precache
flutter doctor

# --- Amplify CLIのインストール ---
# Node.jsとnpmはベースイメージに含まれている
npm install -g @aws-amplify/cli

echo "✅ Post-create script finished successfully!"