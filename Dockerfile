# ↓コメントだけどBuildKit使うための宣言なので消さない
# syntax=docker/dockerfile:1

# *本番構成用
############################
# ビルドのみNode.js使用
# 実行環境ではNode.jsなしで脆弱性リスク軽減
############################

# バージョン管理
ARG RUBY_VERSION=3.4.8
ARG NODE_MAJOR=22

############################
# 1) base（共通）
############################
FROM ruby:${RUBY_VERSION}-slim AS base

# multi-stageではARGのスコープが途切れるのでARGを再宣言
ARG RUBY_VERSION
ARG NODE_MAJOR

# コンテナ内にrailsディレクトリを作り、以降の処理は/railsをカレントディレクトリとして扱う
WORKDIR /rails

    # Railsを本番環境として起動
ENV RAILS_ENV="production" \
    # Gemfile.lockを正として、Gemfileと不整合があればエラーになる
    BUNDLE_DEPLOYMENT="1" \
    # Dockerコンテナ内のGemのインストール先の指定（Bundlerの管理ディレクトリ）
    BUNDLE_PATH="/usr/local/bundle" \
    # developmentとtestグループのGemはインストールしない
    BUNDLE_WITHOUT="development test" \
    # 環境設定
    LANG=C.UTF-8 \
    TZ=Asia/Tokyo

############################
# 2) build（ビルド専用：Nodeあり）
############################
FROM base AS build

# multi-stageではARGのスコープが途切れるのでARGを再宣言
ARG NODE_MAJOR

# OSパッケージ導入　/ Node.js導入（npm同梱）
# apt-get update -qq：aptのパッケージ一覧を更新
# apt-get install -y：対話なしでインストール
# --no-install-recommends：おすすめパッケージを入れない → 余計な依存なしで軽量化
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    # Cコンパイラ一式
    build-essential \
    # psych(yaml読み込み)を使う時に必須の開発用ヘッダ(devだが本番でも必須)
    libyaml-dev \
    # Gemfileで Git から gem を取る場合に必要
    git \
    # タイムゾーン設定
    tzdata \
    # HTTPS証明書ストア。これがないと https 経由のダウンロード（curl等）が失敗しやすい。
    ca-certificates \
    # NodeSource の鍵を取るのに使う。
    curl \
    # 鍵（GPG）を扱う。ダウンロードした鍵を apt が使える形に変換するため。
    gnupg \
    # Node.jsをいれるための前処理
    # NodeSourceの鍵をを置くディレクトリ
    && mkdir -p /etc/apt/keyrings \
    # NodeSourceの署名鍵を取得して保存
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    # NodeSourceのaptリポジトリを追加
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list \
    # リポジトリ追加後に update して nodejs をインストール
    && apt-get update -qq && apt-get install -y --no-install-recommends nodejs \
    # rm -rf /var/lib/apt/lists/*：aptのキャッシュ削除 → 軽量化
    && rm -rf /var/lib/apt/lists/*

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    # バンドルインストール時のキャッシュをDockerコンテナから削除
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# npm設定（本番 build 用）
COPY package.json package-lock.json ./
RUN npm ci && npm cache clean --force

# Railsアプリのコードすべて（一個目の./ホスト側のカレントディレクトリ)を
# コンテナ内(二個目の./コンテナ内のカレントディレクトリ)にコピー = コンテナに載せる
COPY . .

# precompile => アセットを先に用意しておき、読み込み速度向上するRailsの仕組み
# bootsnap => Rails が標準で使う高速化用ライブラリ、Rubyファイルの読み込みを速くする
RUN bundle exec bootsnap precompile app/ lib/

# SECRET_KEY_BASE_DUMMY=1　=> 本番用の秘密情報なしで、アセットプリコンパイルしてOKというフラグ
# !↓がないと、本物のSECRET_KEY_BASEがビルド時に渡されて、ビルドログやイメージレイヤーに残り、秘密情報が漏洩するリスクがある
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

############################
# 3) runtime（実行専用：Nodeなし）
############################
FROM base AS runtime

# 実行時に必要な最小パッケージだけ
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    postgresql-client \
    tzdata \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# build時の成果物をコピー（gems + アプリ + 生成済みassets）
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# 非rootで動かす => 本番環境は一般ユーザーで動かす
# rails(ID 1000)というLinuxグループを作る
RUN groupadd --system --gid 1000 rails && \
# rails(ID 1000) という一般ユーザーを作って、railsグループに入れる
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    # db log storage tmpのみ書き込み権限をrails:rails（一般ユーザー）に移譲
    chown -R rails:rails db log storage tmp
# 以降のユーザー権限はrails
USER 1000:1000

# ENTRYPOINT => コンテナを起動するときにはじめに実行するファイルを指定
# docker-entrypoint　=> DBを使える状態にしてからRails起動するコマンドが書いてある
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
