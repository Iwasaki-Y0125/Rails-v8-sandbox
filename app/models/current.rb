class Current < ActiveSupport::CurrentAttributes
  # Current.session を持てるようにする
  # @current_user や session を引き回さなくて済む
  attribute :session
  # `Current.session.user`と書かなくても`Current.user`で使える
  delegate :user, to: :session, allow_nil: true
end
