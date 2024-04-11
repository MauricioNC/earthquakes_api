Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'features', to: 'features#index'
      post '/features/:id/comments', to: 'comments#create'
    end
  end
end
