Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  # Mount Sidekiq Web UI for monitoring background jobs
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

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

  resources :dashboards, only: [ :index ] do
    collection do
      post :sync_weather
      get :trends
      get :forecasts
      get :environment
    end
  end

  resources :locations, only: [ :index, :create, :destroy ] do
    collection do
      get :search
    end
  end

  # Environmental sensors and monitoring routes
  resources :environmental_sensors do
    collection do
      get :search
      get :nearby
      get :map_data
      post :import_from_openaq
    end

    member do
      post :sync
    end

    # Nested readings for specific sensor
    resources :environmental_readings, only: [ :index, :create, :destroy ] do
      collection do
        get :chartkick
        get :statistics
        get :export
      end
    end
  end

  # Environmental readings routes
  resources :environmental_readings, only: [ :show, :create, :destroy ] do
    collection do
      get :latest
      get :statistics
    end
  end

  # Environmental alerts routes
  resources :environmental_alerts do
    collection do
      get :summary
      get :timeline
    end

    member do
      patch :resolve
    end
  end
end
