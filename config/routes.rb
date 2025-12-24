Rails.application.routes.draw do
  # Mount Sidekiq Web UI for monitoring background jobs
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  get "locations/index"
  get "locations/create"
  get "locations/destroy"
  get "dashboards/index"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  root "dashboards#index"

  resources :dashboards, only: [ :index ]
  resources :locations, only: [ :index, :create, :destroy ]

  post "sync-weather", to: "dashboards#sync_weather", as: "sync_weather"
end
