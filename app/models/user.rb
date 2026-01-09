class User < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error
  # !todo 退会後、postの投稿主はghost_userに切替。退会用サービスクラスでトランザクション処理を作る。(MVP時)
end
