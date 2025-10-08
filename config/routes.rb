Rails.application.routes.draw do
  resources :authors
  get "admin", to: "admin/dashboard#index"
  get "/search", to: "search#index"
  namespace :admin do
    resources :users
    resources :languages
    resources :deities
    resources :schools
    resources :tags do
      collection do
        get :available, defaults: { format: :json }
      end
    end
    resources :authors
  end
  resources :languages
  resources :users, only: %i[ show ]
  resource :session
  resources :passwords, param: :token
  resources :texts do
    member do
      post :upload_files
      delete "delete_file/:file_id", to: "texts#delete_file", as: :delete_file
      post :reorder_files
      post "files/:file_id/add_tags", to: "texts#add_file_tags", as: :add_file_tags
      delete "files/:file_id/remove_tag/:tag_id", to: "texts#remove_file_tag", as: :remove_file_tag
    end
    resources :translations do
      resources :versions do
        member do
          post :generate_cover
          delete :remove_cover
          get :edit_files
          post "files/:file_id/add_tags", to: "versions#add_file_tags", as: :add_file_tags
          delete "files/:file_id/remove_tag/:tag_id", to: "versions#remove_file_tag", as: :remove_file_tag
        end
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "texts#index"
end
