Rails.application.routes.draw do
  get "admin", to: "admin/dashboard#index"
  get "/search", to: "search#index"
  namespace :admin do
    resources :users
    resources :languages
    resources :deities
    resources :schools
    resources :tags
  end
  resources :languages
  resources :users, only: %i[ show ]
  resource :session
  resources :passwords, param: :token
  resources :texts do
    resources :translations do
      resources :versions do
        member do
          get :edit_files
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
