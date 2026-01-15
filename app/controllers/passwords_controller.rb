class PasswordsController < ApplicationController
  # ログイン認証必須を免除
  allow_unauthenticated_access
  # edit / update のみ URLのtokenで対象ユーザーを特定してから処理したい
  before_action :set_user_by_token, only: %i[ edit update ]

  # `new`：パスワード再設定のためのフォームを表示
  # GET /passwords/new
  def new
  end

  # `create`： 入力されたメールアドレス宛に「パスワード再設定リンク」を送る
  # POST /passwords
  def create
    # 1) メールアドレスに一致するユーザーを探す（いなければ nil）
    if user = User.find_by(email_address: params[:email_address])
      # 2) 見つかった場合だけ、再設定メールを送信キューに積む（非同期）
      # !todo 本番時は.deliver_laterに戻す
      PasswordsMailer.reset(user).deliver_now
    end
    # 3) ログイン画面に戻る（メールアドレスの登録の有無にかかわらず同一メッセージ）
    redirect_to new_session_path, notice: "ご入力のメールアドレス宛にパスワードリセットの手順を送信しました"
  end

  # `edit`：メールのリンクを開く=>「新しいパスワード入力フォーム」を表示（token付きURL）
  # GET /passwords/:token/edit
  def edit
  end

  # `update`：新しいパスワードを保存して、ログイン画面へ戻す
  # PATCH /passwords/:token
  def update
    # 1) パスワード更新（許可するパラメータは password / confirmation のみ）
    if @user.update(params.permit(:password, :password_confirmation))
      # 2) 更新できたら、ログイン画面へ（リセット完了の案内）
      redirect_to new_session_path, notice: "パスワードが更新されました"
    else
      # 3) 更新できなければ、同じ token の編集画面へ戻す（不一致など）
      redirect_to edit_password_path(params[:token]), alert: "パスワードが更新できませんでした"
    end
  end

  private
    # token からユーザーを特定する（edit / update の前に呼ばれる）
    def set_user_by_token
      # 1) token を使ってユーザーを探す。見つかれば @user がセットされる
      @user = User.find_by_password_reset_token!(params[:token])
    # 2) token が無効なら、例外処理が走り、最初からやり直してもらう（再設定メール送信フォームへ
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "リンクが無効か、有効期限が切れています。"
    end
end
