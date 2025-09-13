# ベースとなるOSイメージをUbuntuに指定
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Flutterのインストールに必要なツールをインストール
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends git curl unzip

# 安定版(stable)のFlutter SDKをクローンする
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /workspaces/flutter

# Flutterコマンドへのパスを環境変数として設定
ENV PATH="/workspaces/flutter/bin:${PATH}"