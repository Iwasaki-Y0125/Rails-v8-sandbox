# frozen_string_literal: true

module Seeds
  class BodyBuilder
    INTROS = %w[今日は 最近 さっき 今朝 昼 仕事帰り 夜].freeze
    ACTIONS = %w[食べた 見た やった 買った 行った 作った 調べた].freeze
    MOODS = %w[よかった 最高 しんどい まあまあ 微妙 たのしい 眠い うざい].freeze
    ENDS = ["。", "！", "…", "笑"].freeze

    TEMPLATES = [
      "%{intro}、%{topics}を%{action}%{end}",
      "%{intro}は%{topics}のこと考えてた。%{mood}%{end}",
      "%{topics}、%{action}たら%{mood}%{end}",
      "%{intro}の%{topics}が%{mood}%{end}"
    ].freeze

    # words.to_sentence(...) => 配列を文章っぽく連結してくれるメソッド
    def self.jp_list(words)
      words.to_sentence(
        words_connector: "、",      # 単語の区切り文字
        two_words_connector: "と",  # ラーメンと映画
        last_word_connector: "と"   # ラーメン、映画と仕事
      )
    end

    # .sample => 配列からランダムに一つ選ぶ
    def self.build(terms)
      topics = jp_list(terms)
      format(
        TEMPLATES.sample,
        intro: INTROS.sample,
        topics: topics,
        action: ACTIONS.sample,
        mood: MOODS.sample,
        end: ENDS.sample
      )
    end
  end
end
