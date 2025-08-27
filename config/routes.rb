Rails.application.routes.draw do
  # OAuth routes
  get "/auth/atproto", to: redirect("/auth/atproto"), as: :omniauth_authorize
  get "/auth/atproto/callback", to: "sessions#omniauth"
  post "/auth/atproto/callback", to: "sessions#omniauth"
  get "/auth/failure", to: "sessions#failure"
  delete "/sign_out", to: "sessions#destroy", as: :sign_out
  get "/sign_out", to: "sessions#destroy"

  # Login route
  get "login", to: "login#index", as: :login

  get "dashboard/index", as: :dashboard
  get "dashboard/connection_status", to: "dashboard#connection_status"
  get "dashboard/load_more_chats", to: "dashboard#load_more_chats"
  patch "dashboard/update_chat_status/:id", to: "dashboard#update_chat_status", as: :update_chat_status
  get "llm_providers/index"
  get "llm_providers/create"
  get "llm_providers/update"
  get "llm_providers/destroy"
  # Chat routes
  resources :chats, only: [:index, :show, :new, :create, :update, :destroy] do
    resources :messages, only: [:create]
    post :generate_title, on: :member
  end
  
  # LLM Provider routes
  resources :llm_providers, only: [:index, :create, :update, :destroy]
  post "llm_providers/:id/set_default", to: "llm_providers#set_default", as: :set_default_llm_provider
  
  # Root route
  root "login#index"
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
