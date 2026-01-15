class SessionsController < ApplicationController
  # new createのときだけログイン認証必須を免除
  allow_unauthenticated_access only: %i[ new create ]

  # ログイン試行の連打対策（総当たり・ボット対策）
  # 3分間に10回まで。超えたらログイン画面へ戻してメッセージ表示。
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  # `new`：ログインフォーム表示
  # GET /session/new
  def new
  end

  # `create`：認証（メール+パスワード）→ 成功なら **DB Session作成 + cookie発行**
  # POST /session
  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: "Try another email address or password."
    end
  end

  # `destroy`：ログアウト → **DB Session削除 + cookie削除**
  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
