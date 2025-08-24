Rails.application.routes.draw do
  get "dashboard/index"
  get "llm_providers/index"
  get "llm_providers/create"
  get "llm_providers/update"
  get "llm_providers/destroy"
  # Chat routes
  resources :chats, only: [:index, :show, :new, :create] do
    resources :messages, only: [:create]
  end
  
  # LLM Provider routes
  resources :llm_providers, only: [:index, :create, :update, :destroy]
  post "llm_providers/:id/set_default", to: "llm_providers#set_default", as: :set_default_llm_provider
  
  # MCP server endpoint
  post "mcp", to: "mcp#handle"
  
  # Root route
  root "dashboard#index"
  
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
