# Rails-v8-template

本リポジトリは、個人学習目的で作成した**Rails8環境テンプレート**です。

1. このリポジトリについて
2. 設計メモ
3. 構成
4. 使用方法
5. 注意事項・ライセンス

## 1. このリポジトリについて

- 本リポジトリは、個人学習目的で作成した**Rails8環境テンプレート**です。
- 主目的は、環境構築の方法を毎回忘れる自分のための備忘録です。
- コードの再利用については、5. 注意事項・ライセンスをご覧ください。

※なお、本構成はNode.jsによるSSRやサーバー常駐処理が必要な場合は使用できません。

## 2. 設計メモ

- 本番相当の挙動をローカルで再現する
  - RAILS_ENV=production相当の設定、アセットの事前コンパイルをローカル環境で検証できる構成とする。
  - 本番移行後に起きやすい設定差分やブラウザ挙動の問題を、開発段階で事前に把握することを目的とする。

- ビルドと実行を明確に分離する
  - multi-stage build を採用し、Node.jsやコンパイラなどのビルド時専用ツールは実行環境に含めない。
  - アセットはビルド時に生成し、ランタイムでは生成済み成果物のみを使用する。

- 実行環境は最小構成に寄せる
  - 実行環境にはRailsの動作に必要な最小限の依存のみを含める。
  - イメージサイズと脆弱性リスクを抑え、構成の見通しを良くする。
  - ※そのため、Node.jsによるSSRやサーバー常駐処理は動作しません。

## 3. 構成
2025-12-19 時点
- Ruby: 3.4.8
- Rails: 8.0.4
- Node.js: 22
- DB: PostgreSQL 17
- Web server: Puma
- Docker: multi-stage build

## 4. 使用方法

### 4.0. 前提条件
- Docker Desktopが利用可能であること
- GNU Makeが利用可能であること

### 4.1.  リポジトリをクローン
### 4.2.  Dockerデスクトップを起動
### 4.3. 環境変数の入力
`.env.dev.example`をコピーして`.env.dev`を作り、
```bash
cp .env.dev.example .env.dev
```
(任意)`.env.dev`にAPP_NAME=アプリ名を入力

### 4.4. Docker起動（開発環境）
```bash
make dev-build
```
### 4.5. 初回DBセットアップ
```bash
make db-prepare
```

### 4.6. 動作確認
http://localhost:3000 にアクセス

### 4.7.0. ローカル本番環境構築について
#### compose/起動モードの dev / lprod(ローカル本番) の違い
- dev: 通常の開発用（ Railsがdevelopmentで動作 / ホットリロード可能 ）
- lprod: ローカルで本番相当の挙動確認（ Railsがproductionで動作 / ホットリロード不可 ）

lprod(ローカル本番)の想定用途：アセットの表示等がproductionでも動いているか確認する等

### 4.7.1. 事前準備
※ 以降は、先にTailwind/DaisyUIなどのnpmを導入し`package.json`と`package-lock.json`が存在する状態で行ってください。

※ 一旦、npmなしで挙動だけ見たい場合は`Dockerfile.localprod`の87,88行目を一時的にコメントアウトしてください。<br>
  ( npm導入後に必ずコメントアウトをもとに戻してください。戻さないとnpmが反映されません )
```
COPY package.json package-lock.json ./
RUN npm ci && npm cache clean --force
```

### 4.7.2. マスターキーの作成
```bash
# コンテナ起動
make dev

# bash起動
make exec

# マスターキー作成
EDITOR=cat bin/rails credentials:edit

# マスターキー表示
cat config/master.key
# !TODO! 表示された文字列をコピーする

# bashから出る
exit

# コンテナ落とす
make down
```

### 4.7.3. `.env.prod.local`に設定
`.env.prod.local.example`をコピーして`.env.prod.local`を作り、
```bash
cp .env.prod.local.example .env.prod.local
```
`.env.prod.local`に
- (任意)APP_NAME=アプリ名 を入力

- 【!必須】 `RAILS_MASTER_KEY=xxxxxxxxxx`にさっきコピーした値をペースト

※ なお、今回使用した下記ファイルは機密情報になります。
  Githubへコミットしないでください<br>
  （.gitignore の対象にしていますが、念のため自分でも.gitignoreを確認してください）
- .envファイル(exampleを除く)
- master.key

### 4.7.4. ローカル本番検証をビルドして起動
```bash
make lprod-build-nocache
```

### 4.7.6 初回DBセットアップ
```bash
make ldb-prepare
```

### 4.7.7. 動作確認
http://localhost:3000 にアクセス


## 5. 注意事項・ライセンス

### 5-1. 注意事項
- 本リポジトリは個人学習用途を想定しています。
- コードの使用・改変・再配布は可能ですが、動作や結果について一切の保証は行いません。
- 本リポジトリを利用したことによる、いかなる損害についても責任を負いません。

### 5-2. ライセンス
MIT License
