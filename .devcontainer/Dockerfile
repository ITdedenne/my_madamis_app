# ベースとなるコンテナイメージを指定
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Flutterのインストールに必要なツールをインストール
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends git curl unzip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev

# Flutter SDKをクローンし、安定版(stable)に切り替える
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /workspaces/flutter

# Flutterコマンドへのパスを設定
ENV PATH="/workspaces/flutter/bin:${PATH}"

# Flutterの初期セットアップとWebサポートの有効化
RUN flutter precache && \
    flutter config --enable-web && \
    flutter doctor