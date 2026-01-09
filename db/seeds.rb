# db/seeds.rb
# frozen_string_literal: true

# =========================================================
# Similar-posts PoC seed (users/posts/terms/post_terms)
# =========================================================

# ---------- 使用コマンド例 ----------
# make exec
# bin/rails db:seed

# *configありの場合
# USERS=300 POSTS=5000 MIN_TERMS=5 MAX_TERMS=10 TERMS=200 bin/rails db:seed
# 補足
# MIN_TERMS / MAX_TERMS => 一投稿当たりの単語数
# TERMS                 => terms_data.rbで使用する単語数の上限

# *既存データを消して入れ直したいとき（※この4テーブルのデータを削除する）
# RESET=1 bin/rails db:seed
#------------------------------------

puts "[seed] start"

seed = (ENV["SEED"] || "1234").to_i
# srand() => Rubyの乱数の初期値を設定（再現テスト用）
srand(seed)

reset = ENV["RESET"].present?
now = Time.current

if reset
  puts "[seed] RESET=1 => delete all rows in post_terms/posts/terms/users"
  PostTerm.delete_all
  Post.delete_all
  Term.delete_all
  User.delete_all
end

require_relative "seeds/posts_seeder"

Seeds::PostsSeeder.run!(
  users: (ENV["USERS"] || "200").to_i,
  posts: (ENV["POSTS"] || "3000").to_i,
  min_terms: (ENV["MIN_TERMS"] || "2").to_i,
  max_terms: (ENV["MAX_TERMS"] || "5").to_i,
  limit_terms: ENV["TERMS"]&.to_i,
  batch_posts: (ENV["BATCH_POSTS"] || "1000").to_i,
  now: now
)

puts "[seed] done"
