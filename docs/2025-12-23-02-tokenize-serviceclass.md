<!-- 作成中 -->
# 形態素解析 → 品詞情報取得のサービスクラス作成

## 目的
-

## 結論
-

## 変更点
-

## 手順
0. 動作確認( OSにMecabがインストールされいるか & 動作に問題ないか )
    ```bash
    make exec
    mecab -v
    mecab -D
    readlink -f /var/lib/mecab/dic/debian/sys.dic #辞書名確認
    echo "クリスマスってなんかわくわくする🎅" | mecab
    ```

1. Mecab 用のサービスクラスを作成
    ```bash
    mkdir -p app/services/mecab
    touch app/services/mecab/analyzer.rb
    ```




## 参考
- MeCab公式: https://taku910.github.io/mecab/
- natto（GitHub）: https://github.com/buruzaemon/natto
- mecab-ipadic-neologd(GitHub):
 https://github.com/neologd/mecab-ipadic-neologd
- Manpages of manpages-ja in Debian testing : https://manpages.debian.org/testing/manpages-ja/index.html
- Docker ドキュメント日本語化プロジェクト(RUN) :https://docs.docker.jp/develop/develop-images/dockerfile_best-practices.html#run
- 日本語の形態素解析以外にもMeCabを使う、またはMeCabの辞書の仕組み : https://diary.hatenablog.jp/entry/2017/02/04/204344
