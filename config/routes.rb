Rails.application.routes.draw do
resources :users
  get "admin", to: "admin#index"
  resources :languages
  resources :users
  patch "users/:id/edit_role", to: "users#edit_role", as: "edit_role_user"
  resource :session
  resources :passwords, param: :token
  resources :tags
  resources :schools
  resources :deities
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
