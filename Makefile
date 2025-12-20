.PHONY: ch dev dev-build dev-build-nocache lprod lprod-build lprod-build-nocache down lp-down clean ps logs logs-web logs-db exec rails-c g-migr db-migrate db-prepare db-reset db-first lg-migr ldb-migrate ldb-prepare ldb-reset g-con g-model rspec rubocop rubocop-a

# constants
OPTS   := -e HOME=/tmp --user $(shell id -u):$(shell id -g)
DEV    := docker compose --env-file .env.dev -f docker-compose.dev.yml
LPROD  := docker compose --env-file .env.prod.local -f docker-compose.localprod.yml
RAILS  := bin/rails
BUNDLE := bundle exec

# Makeショートカット使い方
# ターミナルで下記のように 'make ???' のように使う
# $ make dev
# $ make down

# *初回の Rails new (初回だけコメントアウト外すかコピペで実行。初回以降実行するとRails newに上書きされるので注意)
# dev-new:
# 	docker compose -f docker-compose.dev.yml run --rm --no-deps --user "$(id -u):$(id -g)" web rails new . --force --database=postgresql

# ====================
# 権限
# ====================

ch:
	sudo chown -R $${USER}:$${USER} .

# ====================
# 起動系
# ====================

# 開発 - 起動
dev:
	$(DEV) up

# 開発 - ビルド
dev-build:
	$(DEV) up --build

# 開発 - 再ビルド（キャッシュ不使用）
# イメージとキャッシュを消して再ビルド→再起動
# 再ビルドは時間がかかるので、基本的に*Dockerを書き換えた場合のみ*行うこと
dev-build-nocache:
	$(DEV) build --no-cache web
	$(DEV) up

# ローカル本番検証 - 起動
lprod:
	$(LPROD) up

# ローカル本番検証 - ビルド
lprod-build:
	$(LPROD) up --build

# ローカル本番検証 - 再ビルド（キャッシュ不使用）
# イメージとキャッシュを消して再ビルド→再起動
# 再ビルドは時間がかかるので、基本的に*Dockerを書き換えた場合のみ*行うこと
lprod-build-nocache:
	$(LPROD) build --no-cache web
	$(LPROD) up


# ====================
# 停止・掃除
# ====================

# 開発環境停止
down:
	$(DEV) down

# ローカル本番環境停止
lp-down:
	$(LPROD) down

# コンテナとボリューム（DB/Gemなど)だけ消える
# キャッシュとイメージは消えないので、*Dodckerを書き換えた場合は、dev-build-nocacheを使うこと*
clean:
	$(DEV) down -v


# ====================
# 状態確認・ログ
# ====================

# 実行中のコンテナ
ps:
	$(DEV) ps

# ログ確認
logs:
	$(DEV) logs -f

# webのみのログ確認
logs-web:
	$(DEV) logs -f web

# dbのみのログ確認
logs-db:
	$(DEV) logs -f db

# *ランタイムにNode.jsが存在しないか確認のコマンドメモ
# docker compose --env-file .env.prod.local -f docker-compose.localprod.yml exec web sh
# node -v
# sh: node: not found　と出れば成功

# ====================
# bash / railsコンソール起動
# ====================

# bash起動
exec:
	$(DEV) exec $(OPTS) web bash

# railsコンソール起動
rails-c:
	$(DEV) exec $(OPTS) web $(RAILS) c


# ====================
# DB操作(開発用)
# ====================

# マイグレーションファイル生成
# make g-migr G="AddIndexToPosts"
g-migr:
	$(DEV) run --rm $(OPTS) web $(RAILS) g migration $(G)

# マイグレーション
db-migrate:
	$(DEV) exec $(OPTS) web $(RAILS) db:migrate

# 初回マイグレーション
db-prepare:
	$(DEV) exec $(OPTS) web $(RAILS) db:prepare

# DB全消し（開発専用）
db-reset:
	$(DEV) exec $(OPTS) web $(RAILS) db:drop db:create db:migrate

# ====================
# DB操作(ローカル本番用)
# ====================

# マイグレーションファイル生成
# make g-migr G="AddIndexToPosts"
lg-migr:
	$(LPROD) run --rm $(OPTS) web $(RAILS) g migration $(G)

# マイグレーション
ldb-migrate:
	$(LPROD) exec $(OPTS) web $(RAILS) db:migrate

# 初回マイグレーション
ldb-prepare:
	$(LPROD) exec $(OPTS) web $(RAILS) db:prepare

# DB全消し（開発専用）
ldb-reset:
	$(LPROD) exec $(OPTS) web $(RAILS) db:drop db:create db:migrate


# ====================
# 生成
# ====================

# コントローラ生成
# make g-con G="Posts index show"
g-con:
	$(DEV) run --rm $(OPTS) web $(RAILS) g controller $(G)

# モデル生成
# make g-model G="Post title:string body:text"
g-model:
	$(DEV) run --rm $(OPTS) web $(RAILS) g model $(G)


# ====================
# テスト
# ====================

# Rspecテスト
rspec:
	$(DEV) exec $(OPTS) web $(BUNDLE) rspec

# Rubocop実行
rubocop:
	$(DEV) exec $(OPTS) web $(BUNDLE) rubocop

# Rubocop自動修正
rubocop-a:
	$(DEV) exec $(OPTS) web $(BUNDLE) rubocop -a
