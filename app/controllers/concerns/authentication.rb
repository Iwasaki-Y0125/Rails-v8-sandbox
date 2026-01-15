module Authentication
  extend ActiveSupport::Concern

  # 処理内容
  # 1. リクエストが来る
  # 2. before_action で require_authentication
  # 3. resume_session が cookie → DB で Current.session 復元
  # 4. 復元できなければログイン画面へ
  # 5. ログイン成功時は start_new_session_for が DBにsession作成 → cookie保存
  # 6. ログアウトは terminate_session が DB削除 → cookie削除

  included do
    # デフォルトで全アクションをログイン必須にする
    before_action :require_authentication

     # view から `authenticated?` を呼べるようにする（ヘッダ表示などに使う）
    helper_method :authenticated?
  end

  class_methods do
    # ログイン不要にしたいアクションだけ、門番をスキップするための宣言用メソッド
    # 例: allow_unauthenticated_access only: %i[new create]
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
     # ログイン済みか？（必要ならcookieからsessionを復元する）
    def authenticated?
      resume_session
    end

    # before_action :require_authenticationの中身
    # ログイン中なら通す。未ログインならログイン画面へ。
    def require_authentication
      resume_session || request_authentication
    end

    # 1リクエスト中の Current.session を優先し、なければ cookie から復元する
    def resume_session
      Current.session ||= find_session_by_cookie
    end

    # 署名付きcookie の session_id から sessions テーブルを引く
    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    # 元いたURLを覚えてログインへ（ログイン後に戻るため）
    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    # ログイン後の遷移先（保存していたURLがあれば優先）
    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    # ログイン開始：DBに session 作成→cookie発行→Currentにセット
    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    # ログアウト：DBセッション削除→cookie削除
    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
