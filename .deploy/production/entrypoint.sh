#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Gemとbundlerのバージョンを合わせる
gem update --system
gem install bundler -v 2.5.3

# Then exec the container's main process (what's set as CMD in the Dockerfile).
bundle config set --local without 'development test' # 調べる
bundle install
bundle exec rake assets:precompile # 調べる
bundle exec rake assets:clean # 調べる
bundle exec rake db:migrate # 調べる
# bundle exec rails db:migrate # 調べる
# bundle exec rails db:seed_fu # 調べる

exec "$@"