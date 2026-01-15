# Rails標準認証 + マジックリンク認証実装の詳細手順

## 前提

- Rails 8 の標準認証ジェネレータを利用する
- `users` テーブルに `email_address` がある想定（ジェネレータの既定に合わせる）
- Active Job が動く（`deliver_later` を使うため）
  - 開発環境では `async` アダプタ等でOK（本番はSolid Queue等）


## Step 1. 認証ジェネレータで “セッション土台” を作る
```bash
make exec
bin/rails generate authentication
bin/rails db:migrate
```
補足: 使用しないpassword系も生成されるが、adminはpassword認証にするなどの変更に備えて機能自体は残し、現時点では導線からは外す運用にする

## Step 2. `users`テーブルに`nonce`を追加（使い回し防止）
```bash
bin/rails g migration AddMagicLinkNonceToUsers magic_link_nonce:integer
bin/rails db:migrate
```

`db/migrate/XXXXXXXXXXXXXX_add_magic_link_nonce_to_users.rb`
```rb
# db/migrate/XXXXXXXXXXXXXX_add_magic_link_nonce_to_users.rb
class AddMagicLinkNonceToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :magic_link_nonce, :integer, null: false, default: 0
  end
end
```

## Step 3. `User`モデル に “マジックリンク用トークン” を定義する

`app/models/user.rb`
```rb
# app/models/user.rb
class User < ApplicationRecord
  # authentication generator が作った関連がある想定
  has_many :sessions, dependent: :destroy

  generates_token_for :magic_login, expires_in: 15.minutes do
    magic_link_nonce
  end
end
```
- `generates_token_for` を使って、用途名 `:magic_login` のトークンを発行できるようにします。
- `magic_link_nonce` で、nonceが変わった瞬間に 過去リンクを失効させます。
#### 注意（重要）
- ブロックの戻り値はトークンに埋め込まれます。パスワード等の機微情報は絶対に入れないこと。

## Step 4. ルーティング
`config/routes.rb`
```rb
# config/routes.rb
resource :magic_login, only: %i[new create]
get "magic_login/:token", to: "magic_logins#show", as: :magic_login_token
```
- `new / create`：メール送信フォームと送信
- `show`：メールのリンククリック（トークン検証 → セッション開始）

## Step 5. コントローラ（送信 → 検証 → セッション開始）
`app/controllers/magic_logins_controller.rb`
```rb
# app/controllers/magic_logins_controller.rb
class MagicLoginsController < ApplicationController
  # authentication generator の concern にある想定
  # 「ログイン不要でアクセス可」にする
  allow_unauthenticated_access only: %i[new create show]

  # 送信フォーム
  def new
  end

  # メール送信
  def create
    email = params[:email].to_s.strip.downcase

    # 方針で選ぶ（どっちでもOK）
    user = User.find_or_create_by!(email_address: email)
    # user = User.find_by(email_address: email)

    token = user.generate_token_for(:magic_login)
    MagicLoginMailer.login_link(user:, token:).deliver_later

    # 「存在した/しない」を匂わせない
    redirect_to magic_login_path,
                notice: "メールを送信しました（届かない場合は迷惑メールも確認してください）"
  end

  # リンククリック → ログイン
  def show
    token = params[:token].to_s
    user  = User.find_by_token_for(:magic_login, token)

    return redirect_to(magic_login_path, alert: "リンクが無効か期限切れです") unless user

    user.with_lock do
      # ここが “二重クリック対策の芯”
      # ロック後にもう一度検証することで、
      # 先行リクエストが nonce を更新済みなら nil になって弾ける
      rechecked = User.find_by_token_for(:magic_login, token)
      return redirect_to(magic_login_path, alert: "リンクが無効か期限切れです") unless rechecked

      user.increment!(:magic_link_nonce)
      start_new_session_for(user)
    end

    redirect_to root_path
  end
end
```
- `allow_unauthenticated_access` / `start_new_session_fo`r` は、Rails 8 標準認証ジェネレータの「型」に沿ったやり方。
- `with_lock` + ロック内再検証 + nonce更新の組み合わせで、同一トークンの二重使用に強くなります。

## Step 6. Mailer設定（リンクを送る）
`app/mailers/magic_login_mailer.rb`
```rb
# app/mailers/magic_login_mailer.rb
class MagicLoginMailer < ApplicationMailer
  def login_link(user:, token:)
    @url = magic_login_token_url(token)
    mail to: user.email_address, subject: "ログインリンク"
  end
end
```
`app/views/magic_login_mailer/login_link.html.erb`
```
<!-- app/views/magic_login_mailer/login_link.html.erb -->
<p>ログインするには以下のリンクを開いてください。</p>
<p><a href="<%= @url %>"><%= @url %></a></p>
<p>このリンクは一定時間で無効になります。</p>
```
## Step 7. dev環境でのURL生成の設定（ActionMailerのhost）
`config/environments/development.rb`
```rb
# config/environments/development.rb
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```
