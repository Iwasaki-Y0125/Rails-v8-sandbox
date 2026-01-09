class CreatePostTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :post_terms do |t|
      t.references :post, null: false, foreign_key: true
      t.references :term, null: false, foreign_key: true

      t.timestamps
    end
    # 同じ投稿に同じtermを二重登録できないようにする,追加・削除・表示にも早い
    add_index :post_terms, [ :post_id, :term_id ], unique: true

    # 類似検索で「term→post」を引くので逆順も張る
    add_index :post_terms, [ :term_id, :post_id ]
  end
end
