# Rails-v8-sandbox

本リポジトリは、個人学習目的で作成した**Rails8環境での技術検証用リポジトリ**です。

## 検証項目

1. Mecab(Natto)で名詞抽出できるか

2. NTT極性辞書でスコア出せるか

3. PostgreSQLで「似た投稿」クエリが成立するか

4. Solid Queueで解析を非同期にできるか

5. Rails標準認証 + マジックリンク + メール

## 構成
2025-12-19 時点
- Ruby: 3.4.8
- Rails: 8.0.4
- Node.js: 22
- DB: PostgreSQL 17
- Web server: Puma
- Docker: multi-stage build

## Licenses / Third-party notices
See `docs/third_party_notices.md`.
