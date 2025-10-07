Rails.application.routes.draw do
  # Devise routes for user authentication
  devise_for :users

  # Authenticated root - dashboard
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Unauthenticated root - redirect to sign in
  root "dashboard#index"

  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Resource routes
  resources :customers
  resources :appointments
  resources :messages, only: [:index, :show, :create] do
    collection do
      get 'thread/:customer_id', to: 'messages#thread', as: 'thread'
    end
  end

  # Settings namespace
  namespace :settings do
    resource :business, only: [:edit, :update]
    resources :twilio_phone_numbers, only: [:index, :new, :create]
  end

  # Twilio webhooks
  post "webhooks/twilio/inbound", to: "twilio_webhooks#inbound"
  post "webhooks/twilio/status", to: "twilio_webhooks#status_callback"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
