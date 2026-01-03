# frozen_string_literal: true

Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "hello_world", to: "hello#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  # Authentication API endpoints
  namespace :api do
    namespace :v1 do
      namespace :auth do
        scope module: :authentication do
          post "register", to: "registrations#create"
          post "login", to: "sessions#create"
        end
      end

      resources :invoices, only: [ :create, :index ]
    end
  end
end
