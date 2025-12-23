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
