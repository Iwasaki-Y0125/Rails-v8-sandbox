class Post < ApplicationRecord
  belongs_to :user

  has_many :post_terms, dependent: :destroy
  has_many :terms, through: :post_terms
end
