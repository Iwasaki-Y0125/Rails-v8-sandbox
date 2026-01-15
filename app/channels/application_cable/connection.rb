# ブラウザとの通信でWebSocketを"誰としてつなげるか"確定させるクラス
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # 接続を識別するキーとして current_user を宣言
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        # cookies.signed[:session_id] : 改ざん検知つきの署名済みCookie
        if session = Session.find_by(id: cookies.signed[:session_id])
          # 引き当てたユーザーでcurrent_userを確定させる
          self.current_user = session.user
        end
        # 見つからなければnilが返り、`reject_unauthorized_connection`で接続が拒否される
      end
  end
end
