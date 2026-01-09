# frozen_string_literal: true

require_relative "terms_data"
require_relative "body_builder"

module Seeds
  class PostsSeeder
    # run! => クラスメソッド 引数はすべて「キーワード引数」になる
    def self.run!(
      users: 200,
      posts: 3000,
      min_terms: 2,
      max_terms: 5,
      limit_terms: nil,
      batch_posts: 1000,
      now: Time.current
    )
      # ---------- config ----------
      terms_pool = Seeds::TermsData::ALL
      if limit_terms && limit_terms > 0
        limit_terms = [ limit_terms, terms_pool.size ].min
        terms_pool = terms_pool.sample(limit_terms)
      end

      raise "[seed] terms_pool empty" if terms_pool.empty?

      max_terms = [ max_terms, terms_pool.size ].min
      min_terms = [ min_terms, max_terms ].min

      # ---------- users upsert ----------
      user_rows = (1..users).map do |i|
        {
          email: "seeduser-#{i.to_s.rjust(5, '0')}@example.com",
          created_at: now,
          updated_at: now
        }
      end
      # .upsert_all => ユーザー作成しつつ,カッコ内の引数とかぶりのデータがあった場合はUPDATEに切り替えて処理してくれる
      User.upsert_all(user_rows, unique_by: :index_users_on_email)
      # idのみを配列に入れる(シートメールアドレスのみ)
      user_ids = User.where("email LIKE ?", "seeduser-%@example.com").pluck(:id)
      raise "[seed] user_ids empty" if user_ids.empty?

      # 作成ポストのカウンタ
      posts_inserted = 0
      # posts: 3000の目標件数を超えるまでループ処理
      while posts_inserted < posts
        # バッチ処理のsize設定
        # 例えば、posts=2500, batch_posts=1000の場合、
        # 最終回の500で処理が走るようにどちらかの最小値をとる
        size = [ batch_posts, posts - posts_inserted ].min

        rows = Array.new(size) do
          picked = terms_pool.sample(rand(min_terms..max_terms)).uniq
          body = Seeds::BodyBuilder.build(picked)
          # .sample() => 重複なしでランダム抽出
          # rand() => rangeで指定された範囲の値を返す
          # .uniq　=> 念のための重複削除。保険。

          {
            user_id: user_ids.sample,
            body: body,
            sentiment_score: 0.0,   # いったん0.0であとでポジネガ分析する
            visibility: (rand < 0.9 ? "public" : "private"),
            reply_mode: (rand < 0.85 ? "open" : "limited"),
            created_at: now,
            updated_at: now
          }
        end

        # .insert_all! => 高速でcreate!する。モデルを通さないのでバリデーションは効かない。そのため、スキーマ制約に引っかかる場合は即エラーで落ちる。seed作成で便利。
        Post.insert_all!(rows)
        posts_inserted += size
        puts "[seed] posts=#{posts_inserted}/#{posts}"
      end
    end
  end
end
