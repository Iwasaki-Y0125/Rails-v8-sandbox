# frozen_string_literal: true

# 使い方:
# DEBUG=1 TEXT="カレー食べたい。最近仕事が忙しい" bin/rails runner script/check_similar_posts.rb
#
#   1) 投稿作成
#   2) 形態素解析
#   3) 名詞抽出
#   4) ポジネガ分析
#   5) 解析結果の保存
#   6) 類似投稿検索 => レコメンド表示

MAX_LEN = 140
DEFAULT_SIMILAR_POSTS_LIMIT = 10
DEFAULT_TEXT = "今日は映画を観た。カレー食べたい。仕事が忙しい。".freeze

text  = (ENV["TEXT"] || DEFAULT_TEXT).to_s
limit = (ENV["LIMIT"] || DEFAULT_SIMILAR_POSTS_LIMIT).to_i
debug = ENV["DEBUG"] == "1"

raise "TEXT is too long (max #{MAX_LEN})" if text.length > MAX_LEN

# -------------------------
# 1) 投稿作成 => 解析前の状態で保存
# -------------------------
user = User.first || User.create!(email: "dev@example.com")
post = Post.create!(user_id: user.id, body: text)

puts "[created] post_id=#{post.id} user_id=#{user.id} body=#{post.body.inspect}"

begin
  # -------------------------
  # 2) 形態素解析
  # -------------------------
  analyzer = Mecab::Analyzer.new
  tokens = analyzer.tokens(text)

  puts "[tokens] size=#{tokens.size}" if debug

  # -------------------------
  # 3) 名詞抽出
  # -------------------------
  nouns = Mecab::NounExtractor.new(analyzer: analyzer).call(text)
  nouns = nouns.map(&:to_s).map(&:strip).reject(&:empty?).uniq

  puts "[nouns] count=#{nouns.size}" if debug
  puts "  nouns=#{nouns.join(', ')}" if debug

  # -------------------------
  # 4) ポジネガ分析
  # -------------------------
  result = SENTIMENT_SCORER.score_tokens(tokens)
  score = result[:mean].to_f

  if debug
    counts = result[:counts] || {}
    puts "[sentiment] mean=#{score} total=#{result[:total]} matched=#{counts[:matched]} "\
        "pos=#{counts[:pos]} neg=#{counts[:neg]} neu=#{counts[:neu]}"

    puts "-- HITS (top 10)"
    (result[:hits] || []).first(10).each do |h|
      puts "  [i=#{h[:i]}] type=#{h[:type]} phrase=#{h[:phrase]} "\
          "raw=#{h[:raw]} applied=#{h[:applied]} negated=#{h[:negated]}"
    end

    puts "-- HITS (last 5)"
    (result[:hits] || []).last(5).each do |h|
    puts "  [i=#{h[:i]}] type=#{h[:type]} phrase=#{h[:phrase]} "\
          "raw=#{h[:raw]} applied=#{h[:applied]} negated=#{h[:negated]}"
    end
  end

# -------------------------
# 5) 解析結果の保存
# -------------------------
  Post.transaction do
    post.update!(sentiment_score: score)
    Posts::TermsUpserter.call(post_id: post.id, terms: nouns)
  end

  puts "[saved] score=#{post.reload.sentiment_score} post_terms=#{PostTerm.where(post_id: post.id).count}"

rescue => e
  puts "[analysis] ERROR: #{e.class}: #{e.message}"
  puts "[analysis] post remains: post_id=#{post.id} sentiment_score=#{post.sentiment_score}"
end

# -------------------------
# 6) 類似投稿検索 => レコメンド表示
# -------------------------
results = Posts::SimilarPostsQuery.call(post_id: post.id, limit: limit)

puts "\n[similar_posts] count=#{results.length}"

results.each_with_index do |p, i|
  overlap = p.attributes["overlap"]
  puts format(
    "  #%02d id=%s overlap=%s score=%s created_at=%s body=%s",
    i + 1, p.id, overlap, p.sentiment_score, p.created_at, p.body.inspect
  )
end
