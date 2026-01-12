class MatchingExcludedTerm < ApplicationRecord
  # columns: term:text, enabled:boolean, created_at, updated_at
  validates :term, presence: true, uniqueness: true
  scope :enabled, -> { where(enabled: true) }
end
