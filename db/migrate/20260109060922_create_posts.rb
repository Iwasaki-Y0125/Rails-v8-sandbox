class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.float :sentiment_score, null: false, default: 0.0
      t.string :visibility, null: false, default: "public"
      t.string :reply_mode, null: false, default: "open"

      t.timestamps
    end
    add_index :posts, [:visibility, :reply_mode]
  end
end
