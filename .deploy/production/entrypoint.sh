#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# cockroachdb：https://www.cockroachlabs.com/docs/v23.1/build-a-ruby-app-with-cockroachdb-activerecord
git clone https://github.com/cockroachlabs/example-app-ruby-activerecord
cd example-app-ruby-activerecord
which libpq
bundle config --local build.pg --with-opt-dir=/usr/local/opt/libpq
cd /app

# Gemとbundlerのバージョンを合わせる
gem install bundler -v 2.5.3

bundle lock --add-platform x86_64-linux;

# ffiのキャッシュを有効化
bundle config set --local BUNDLE_CACHE__FFI true

# 不要なgemをインストールしない
bundle config set --local without 'development test'

# 必要なgemがすでにインストールされているか確認
bundle check || bundle install -j2 --retry=2 # 並列実行数を指定してエラー対策 {Ran out of memory (used over 512MB) while running your code.}

# bundle exec rails assets:precompile RAILS_ENV=production # 静的アセット(css, js, img)を事前に一つのファイルに結合コンパイル
# bundle exec rails assets:clean RAILS_ENV=production # アセットパイプラインによって生成された古い静的アセットをクリーンアップ
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

bundle exec rails db:migrate
# bundle exec rails db:migrate RAILS_ENV=production
# || bundle exec rails db:create && bundle exec rails schema:load

# bundle exec rails db:seed_xxxxx # データベースの初期化

exec "$@"