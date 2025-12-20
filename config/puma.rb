# Puma設定ファイルの概要

# この設定ファイルは、PumaというWebサーバーの設定を行います。
# Pumaは、複数のプロセス（ワーカー）を起動し、各プロセス内で複数のスレッドを使ってリクエストを処理します。

# ワーカー数： WEB_CONCURRENCYという環境変数で制御できます。複数のワーカーを起動したい場合に設定します。デフォルトは1つです。

# スレッド数： 各ワーカーが使用するスレッドの数を設定します。
# スレッド数を増やすメリット： より多くのリクエストを同時に処理できるようになります（スループットの向上）。
# スレッド数を増やすデメリット： CRubyのGVL（グローバルVMロック）の影響で、処理速度が低下する可能性があります（レイテンシの悪化）。

# デフォルトは3スレッドで、これはスループットとレイテンシのバランスを取るための推奨値です。
# リソースプールの設定： Active Record (Rails)のdatabase.ymlのpoolパラメータなど、
# データベース接続やその他のリソースプールを使用するライブラリは、スレッド数以上の接続数を持つように設定する必要があります。

threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# HTTP ポート設定　Railsは伝統的に3000
# RenderなどでデプロイしたときPORTがRender側で指定されてそちらが優先される
port ENV.fetch("PORT", 3000)

# tmp_restartプラグイン
# 本番環境で設定変更や軽微な不整合が起きたときに、コンテナを落とさずにPumaのみを安全に再起動する
# bin/rails restartを実行 => tmp/restart.txtのタイムスタンプが更新 =>　Puma側がtmp/restart.txtを定期的に見に行って更新があれば再起動
plugin :tmp_restart

# Solid Queueプラグイン　バックグラウンドジョブ実行機構
# Solid Queueをpumaの中、単一サーバーで動かしたいときにSOLID_QUEUE_IN_PUMAをtrueに設定する
# !TODOバックグラウンド処理の実装になったらまた詳しく調べる
plugin :solid_queue if ENV["SOLID_QUEUE_IN_PUMA"]

# PIDファイルを使う人だけ使えるように残してある設定
# Dockerは1コンテナ=1プロセスだから、PIDファイルの設定は基本的に不要
pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
