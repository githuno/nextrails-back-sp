Rails.application.routes.draw do
  get '/', to: 'hello#create'
  namespace :api do
    namespace :v1 do
      resources :posts, only: [:index, :show, :create, :update, :destroy]
    end
  end

  namespace :gyve do
    namespace :v1 do
      # post '/get_images', to: 'get_images#image'
      post '/get_images', to: 'images#show'
      post '/post_image', to: 'images#create'
    end
  end

  resources :posts
end
