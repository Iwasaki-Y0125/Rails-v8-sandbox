class Term < ApplicationRecord
  has_many :post_terms, dependent: :destroy
  has_many :posts, through: :post_terms
end
