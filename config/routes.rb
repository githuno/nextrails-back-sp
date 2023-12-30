Rails.application.routes.draw do
  get '/', to: 'hello#create'
  namespace :api do
    namespace :v1 do
      resources :posts, only: [:index, :show, :create, :update, :destroy]
    end
  end
  resources :posts

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
      post '/retrun_ply', to: 'splats#crete_splat'


    end
  end
  
end
