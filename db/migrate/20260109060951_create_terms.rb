class CreateTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :terms do |t|
      t.text :term, null: false

      t.timestamps
    end
    add_index :terms, :term, unique: true
  end
end
