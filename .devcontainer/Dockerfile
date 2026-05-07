# ベースとなるOSイメージをUbuntuに指定
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Flutterのインストールに必要なツールをインストール
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends git curl unzip

# インストール先を /usr/local/flutter に変更
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /usr/local/flutter

# 【追加】所有権を vscode ユーザーに変更しておく（ここが重要です）
RUN chown -R vscode:vscode /usr/local/flutter

# 環境変数のパスを更新
ENV PATH="/usr/local/flutter/bin:${PATH}"