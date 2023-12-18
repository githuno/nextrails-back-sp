Rails.application.routes.draw do
  namespace :api do
    get '/hello', to: 'hello#create'
    namespace :v1 do
      resources :posts, only: [:index, :show, :create, :update, :destroy]
    end
  end

  namespace :gyve do
    namespace :v1 do
      post '/post/:method', to: 'posts#handle_gyve_request'
      get '/post/:method', to: 'posts#handle_gyve_request'
    end
  end

  resources :posts
end
