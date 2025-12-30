# frozen_string_literal: true

module Sentiment
  class Scorer
    DEFAULT_TARGET_POS = %w[名詞 形容詞 動詞 副詞].freeze

    # 否定の基本形 (否定検出は tokens 全体を見る)
    NEGATION_BASES = %w[
      ない ぬ ず ん
      ません ないです ないだ
      ないだろ ないだろう ないでしょう
      まい
    ].freeze

    def initialize(
      pn_lexicon:,
      wago_lexicon:,
      target_pos: DEFAULT_TARGET_POS,
      negation_window: 2    # ←否定が何語後までに来たら反転するか
    )
      raise ArgumentError, "pn_lexicon is required" unless pn_lexicon
      raise ArgumentError, "wago_lexicon is required" unless wago_lexicon

      @pn = pn_lexicon
      @wago = wago_lexicon
      @target_pos = target_pos
      @negation_window = negation_window
    end

    #  tokens: [{ surface:, base:, pos: }, ...]
    def score_tokens(tokens)
      raise ArgumentError, "tokens must be an Array" unless tokens.is_a?(Array)

      # 1) スコア対象(名詞 形容詞 動詞 副詞)だけ抽出 / インデックス付き
      scored_tokens = []
      tokens.each_with_index do |t, i|
        next unless @target_pos.include?(t[:pos])
        scored_tokens << [t, i]
      end

      # hits : 評価語（1トークン1件）
      # hits: { i(Integer) => { type:, i:, phrase:, raw:, applied:, negated: }, ... }
      hits = {}

      # 2) pn: 名詞編
      scored_tokens.each do  |t, i|
        key = base_or_surface(t[:base], t[:surface])
        s = @pn.score(key)
        next if s.nil?

        hits[i] = build_hit(type: :pn, i: i, phrase: key, score: s)
      end

      # 3) wago: 用言編
      scored_tokens.each do |t, i|
        next if hits.key?(i)
        key = base_or_surface(t[:base], t[:surface])
        s = @wago.score(key)
        next if s.nil?

        hits[i] = build_hit(type: :wago, i: i, phrase: key, score: s)
      end

      # 4) 否定反転：全トークンから否定語の位置を拾って、直前のヒット1個を反転
      apply_negation!(hits, tokens)

      # 5) 集計 ( スコア / 合計 / 平均値 )
      hit_values = hits.values

      scores = hit_values.map { |h| h[:applied].to_f }
      total = scores.sum
      mean = scores.empty? ? 0.0 : (total / scores.length)

      {
        total: total,
        mean: mean,
        counts: {
          matched: scores.length,
          pos: scores.count { |x| x > 0 },
          neg: scores.count { |x| x < 0 },
          neu: scores.count { |x| x == 0 }
        },
        hits: hit_values.sort_by { |h| h[:i] }
      }
    end

    private

    def build_hit(type:, i:, phrase:, score:)
      {
        type:    type,     # 辞書タイプ(:pn or :wago)
        i:       i,        # トークンインデックス
        phrase:  phrase,   # 該当フレーズ
        raw:     score,    # 元のスコア
        applied: score,    # 否定反転後のスコア
        negated: false     # 否定反転済みフラグ
      }
    end

    # 正規化
    def base_or_surface(base, surface)
      base_str = base.to_s
      return surface.to_s if base_str.empty? || base_str == "*"
      base_str
    end

    # 否定語かどうかチェック
    def negation_token?(t)
      base = t[:base].to_s
      surf = t[:surface].to_s
      NEGATION_BASES.include?(base) || NEGATION_BASES.include?(surf)
    end

    # 否定反転処理
    # 1. 文章の中で否定語（ない/ず/ません…）が出てくる場所を探す
    # 2. 否定語の 直前か一つ飛んで前 *1にある評価語ヒットを探す
    #   （ *1/ negation_window = 2）
    # 3. 見つかった評価語のスコア applied を 符号反転する（+1→-1、-1→+1）

    # hits: [{ type:, i:, phrase:, raw:, applied:, negated: }, ...]
    # tokens: [{ surface:, base:, pos: }, ...]

    def apply_negation!(hits, tokens)
      # 評価後がなければ即終了
      return if hits.empty?

      #
      # hits_by_i = hits.to_h { |h| [h[:i], h] }

      tokens.each_with_index do |t, neg_i|
        # tokensに否定語がなければここで終了
        next unless negation_token?(t)

        # 否定語が見つかったら、直前〜negation_window(=2)語前まで繰り返す
        # 1.upto(2) do |d|
        # d = 1 のとき：直前の語
        # d = 2 のとき：一つ飛んで前の語
        1.upto(@negation_window) do |d|
          idx = neg_i - d
          break if idx < 0

          # 評価語hitsがなければ、さらにdを増やす
          h = hits[idx]
          next unless h

          # 念のための二重反転防止
          next if h[:negated]

          # 否定反転処理
          h[:applied] *= -1
          h[:negated] = true

          # 一番近い語で反転出来たら即離脱
          break

        end
      end
    end
  end
end
