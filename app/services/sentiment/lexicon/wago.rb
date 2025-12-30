# frozen_string_literal: true

module Sentiment
  module Lexicon
    # wago.121808.pn:
    #   ラベル(例: ポジ（評価）) \t 表現(単語 or フレーズ)
    #
    # 「語幹のみ」採用：
    # - フレーズを分解して先頭要素（語幹）だけ辞書化する
    # - 活用語が3つ以上（= 要素数が多すぎる）ものは除外してノイズを減らす
    class Wago
      LABEL_MAP = {
        "ポジ（評価）" => 1,
        "ポジ（経験）" => 1,
        "ネガ（評価）" => -1,
        "ネガ（経験）" => -1
      }.freeze

      def initialize(path, max_terms: 3)
        @path = path
        @max_terms = max_terms
        @dict = nil
      end

      # 1語（語幹）のスコアを返す
      def score(word)
        dict[word]
      end

      def dict
        @dict ||= load_dict
      end

      private

      def load_dict
        raise "wago lexicon not found: #{@path}" unless File.exist?(@path)

        h = {}

        File.foreach(@path, encoding: "UTF-8") do |line|
          line = line.strip
          next if line.empty?

          # まずタブで「ラベル」と「表現」を分離（wagoはラベル\t表現 の形式）
          label, expr_str = line.split("\t", 2)
          next if label.nil? || expr_str.nil?

          score = LABEL_MAP[label]
          next if score.nil?

          # 表現（単語 or フレーズ）を空白で分解
          expr = expr_str.strip.split(/\s+/)
          next if expr.empty?

          # 要素数が多いものは除外（ノイズ削減）
          next if expr.length > @max_terms

          # 語幹（先頭要素）のみ採用
          stem = expr[0]
          next if stem.nil? || stem.empty?

          # 重複があっても最初の値を残す
          h[stem] ||= score
        end

        h
      end
    end
  end
end
