#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Gemとbundlerのバージョンを合わせる
gem install bundler -v 2.5.3

# ffiのキャッシュを有効化
bundle config set --local BUNDLE_CACHE__FFI true

# ネットワークを使うGemのインストールをスキップ
bundle config set --local without 'network'

# 不要なgemをインストールしない
bundle config set --local without 'development test'

# 必要なgemがすでにインストールされているか確認
bundle check || bundle install -j2 --retry=2 # 並列実行数を指定してエラー対策 {Ran out of memory (used over 512MB) while running your code.}

# bundle exec rake assets:precompile # 静的アセット(css, js, img)を事前に一つのファイルに結合コンパイル
# bundle exec rake assets:clean # アセットパイプラインによって生成された古い静的アセットをクリーンアップ
#
# # libディレクトリ内に配置されたJavaScriptファイルが、Railsのビューで使用される静的アセットとしてではなく、
# # Open3.popen3などの方法で直接実行されるスクリプトとして使用される場合、rake assets:precompileは不要です。
# # rake assets:precompileは、Railsのビューで使用されるJavaScript、CSS、画像などの静的アセットを
# # 事前にコンパイル（結合、圧縮、フィンガープリント付加など）するためのタスクです。
# # これらの静的アセットは、通常、app/assetsディレクトリ内に配置されます。
# # 一方、libディレクトリは、アプリケーション固有のライブラリを格納するための場所であり、
# # ここに配置されたファイルはアセットパイプラインの対象外です。
# # したがって、libディレクトリ内のJavaScriptファイルを直接実行する場合、
# # rake assets:precompileを実行する必要はありません。

bundle exec rake db:migrate # データベースのマイグレーション
# bundle exec rails db:seed_xxxxx # データベースの初期化

exec "$@"