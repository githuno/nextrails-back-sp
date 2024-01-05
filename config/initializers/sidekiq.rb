# 

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
  Sidekiq::BasicFetch::TIMEOUT = 30 # 15 seconds：https://community.fly.io/t/managing-redis-rate-limits-on-sidekiq-and-rails/6741/8
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

# workerを同時起動（bundle exec sidekiq -q default）する必要がある。

# config/initializers/sidekiq.rb
# cinfig/application.rb
# config/routes.rb

# config/sidekiq.yml
# config/cable.yml
# Gemfile
# Gemfile.lock
# Procfile
# .env

