class CreateMatchingExcludedTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :matching_excluded_terms do |t|
      t.text :term, null: false
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end
    add_index :matching_excluded_terms, :term, unique: true
    add_index :matching_excluded_terms, :enabled
  end
end
