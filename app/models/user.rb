class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :posts, dependent: :restrict_with_error
  # !todo 退会後、postの投稿主はghost_userに切替。退会用サービスクラスでトランザクション処理を作る。(MVP時)

  # パスワードリセット用トークンを生成（15分で期限切れ）
  generates_token_for :password_reset, expires_in: 15.minutes do
    # password_digestの末尾10文字をtokenに混ぜる
    # => パスワード変更でpassword_digestが変更されることをトリガーに、過去のリセットリンクを全部失効させる
    password_digest&.last(10)
  end

  # コントローラー側で呼び出しやすくするためのラッパー
  def self.find_by_password_reset_token!(token)
    find_by_token_for!(:password_reset, token)
  end
end
