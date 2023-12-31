Rails.application.routes.draw do

  # # redis-GUI
  if Rails.env.development?
    require 'sidekiq/web'
    # localhost:3000/sidekiqにアクセスすると、Sidekiqの管理画面が表示される。
    # ただし、バックグラウンドでupstashへ大量のリクエストを送信し続ける。
    mount Sidekiq::Web => '/sidekiq'
  end

  # root
  get '/', to: 'hello#create'
  # Tailscale API
  get '/tail/up', to: 'tailscale#up'
  get '/tail/check', to: 'tailscale#check'
  get '/tail/down', to: 'tailscale#down'
  get '/tail/status', to: 'tailscale#status'

  # API test
  namespace :api do
    namespace :v1 do
      resources :posts, only: [:index, :show, :create, :update, :destroy]
    end
  end
  resources :posts


  # Gyve API
  namespace :gyve do
    namespace :v1 do
      post '/get_images', to: 'images#show'
      post '/post_image', to: 'images#create'
      post '/del_image', to: 'images#destroy'
      post '/get_presignedUrl', to: 'videos#pre_create'
      post '/video_up', to: 'videos#create'
      post '/get_objects', to: 'objects#index'
      post '/del_object', to: 'objects#destroy'
      post '/create_3d', to: 'objects#create_3d'
      # gaussian
      post '/return_ply', to: 'splats#create_splat'
      # redis_test
      get '/redis_test', to: 'redis_test#test'
    end
  end
  
end
