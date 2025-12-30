# Sentiment（PN/Wago語幹版）ローダー＆スコアラー作業 途中経過メモ

スコアラーをリファクタ後、動作確認

## 目的
- 日本語評価極性辞書（PN / wago）で投稿テキストの簡易ポジネガスコアを出す
- MeCab（Natto）の `tokens(Hash配列)` をそのまま入力にできる形にする
- wago はまず「語幹のみ（先頭語のみ）」でMVP実装

## 結論
- PN：`word \t label(p/n/e/ノイズ) \t category` → `p=1, n=-1, e=0` のHash辞書化（ノイズ除外）
- Wago：`ラベル \t 表現(単語/フレーズ)` → 表現を空白分割し **先頭語（語幹）のみ** をHash辞書化
- Scorer：対象品詞（名詞/形容詞/動詞/副詞）を pn/wago で1語一致。否定語（baseが `ない/ず/ません...`）は tokens 全体から検出し、直前window以内のヒットを反転

## 変更点
- `Sentiment::Lexicon::PN`：`File.foreach` で1行ずつ読み込み、`LABEL_MAP(p/n/e)` のみ採用、遅延ロード
- `Sentiment::Lexicon::Wago`：`line.split("\t", 2)` で label/expr を分離 → exprを空白分割 → 語幹のみ採用（`max_terms` で長すぎる表現は除外、重複は先勝ち）
- `Sentiment::Scorer`：`each_with_index` で位置を保持。wagoは語幹版なので n-gram処理（`score_phrase/scan_ngrams`）は使わない

## 手順
1. Docker内に辞書を配置（例：`/opt/sentiment_lex/`）
2. PN/Wagoローダーで辞書をHash化
3. `Scorer#score_tokens(tokens)` を実装（語幹1語一致 + 否定反転）
4. `Analyzer#tokens(text)` の戻りを Scorer に渡して評価

## 動作確認
- `pn.score("最高")` / `wago.score("買い得")` が引ける
- `"最高"` がポジ寄り、`"最高じゃない"` が反転する（window=2想定）

## 参考
- 日本語評価極性辞書 配布ページ（東北大学 乾・岡崎研究室）
https://www.cl.ecei.tohoku.ac.jp/Open_Resources-Japanese_Sentiment_Polarity_Dictionary.html
- Qiita: 3. Pythonによる自然言語処理　5-4. 日本語文の感情値分析［日本語評価極性辞書（名詞編）］https://qiita.com/y_itoh/items/4693bd8f64ac811f8524
- Qiita: 3. Pythonによる自然言語処理　5-5. 日本語文の感情値分析［日本語評価極性辞書（用言編）］https://qiita.com/y_itoh/items/7c528a04546c79c5eec2
- MeCab公式: https://taku910.github.io/mecab/
- natto（GitHub）: https://github.com/buruzaemon/natto
