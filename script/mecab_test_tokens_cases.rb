# frozen_string_literal: true

require "bundler/setup"
require_relative "../config/environment"

# 動作確認 ==============================
# $ make exec
# $ ruby script/mecab_tokens_cases.rb > tmp/mecab_tokens_cases.log
# ======================================

# MeCabの動作確認用スクリプト（複数ケース版）

cases = [
  # topic: クリスマス/食べ物, sentiment: +
  "今年のクリスマスはガストの丸どりチキン買った！楽しみ〜🎄🍗",

  # topic: クリスマス/仕事/寒さ, sentiment: -
  "クリスマスなのに仕事だるい。。。😩めっちゃ寒いし。。。最悪",

  # topic: クリスマス/食べ物, sentiment: +
  "クリスマスは次の日に安売りされるケーキを買うのが楽しみなんだよね",

  # topic: クリスマス/音楽, sentiment: +
  "クリスマスソングは羊文学の1999が一番好き！ https://example.com",

  # topic: クリスマス/音楽, sentiment: -
  "街中でクリスマスソング流れてるのうざいからやめてほしい",

  # topic: クリスマス/映画, sentiment: +
  "クリスマスの映画といえば『ホーム・アローン』だよね！笑えるし感動もするし最高！彼氏と観る予定😊🤍",

  # topic: クリスマス/映画, sentiment: +
  "クリスマスの映画といえば「東京ゴットファザーズ」でしょ。笑いあり涙ありの名作。今敏監督っぽいどこか不気味な感じもよき。ひさびさに観たけどやっぱ好きだなあ。布教しようかな",

  # topic: 映画, sentiment: +
  "映画といえば「東京ゴットファザーズ」でしょ。笑いあり涙ありの名作。今敏監督っぽいどこか不気味な感じもよき。ひさびさに観たけどやっぱ好きだなあ。布教しようかな",

  # topic: 映画, sentiment: -
  "「パプリカ」すすめられて見たけど、なんか難しくてよくわからなかった。今敏監督のほかの作品も前見たことあるけどあんまり好きじゃなかったなあ",

  # topic: 人間関係/雑談, sentiment: 0
  "最近バ先の人がサブカルわかってる感出してかっこつけてくるのまじウケる笑",

  # topic: 動物/夢/生活, sentiment: +
  "いつか大型犬を飼いたい。いっぱいお金稼いで広い庭つきの大きい戸建てに住みたい。夢は大きく！",

  # topic: 動物, sentiment: +
  "猫かわいい🐈猫しか勝たん"
]


analyzer = Mecab::Analyzer.new

cases.each do |t|
  puts "\n---\n#{t}"
  # pp は pretty print で、配列やHashを 見やすく整形して表示するメソッド
  pp analyzer.tokens(t)
end
