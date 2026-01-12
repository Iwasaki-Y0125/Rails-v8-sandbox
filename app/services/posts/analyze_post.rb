# app/services/posts/analyze_post.rb
module Posts
  class AnalyzePost
    def self.call(post_id:)
      post = Post.find(post_id)
      text = post.body.to_s

      analyzer = Mecab::Analyzer.new
      tokens = analyzer.tokens(text)

      nouns = Mecab::NounExtractor.new(analyzer: analyzer).call(text)
      nouns = nouns.map(&:to_s).map(&:strip).reject(&:empty?).uniq

      result = SENTIMENT_SCORER.score_tokens(tokens)
      score = result[:mean].to_f

      Post.transaction do
        post.update!(sentiment_score: score)
        Posts::TermsUpserter.call(post_id: post.id, terms: nouns)
      end

      { post: post, score: score, nouns: nouns, sentiment: result }
    end
  end
end
