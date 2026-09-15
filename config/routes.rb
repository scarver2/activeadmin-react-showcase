# config/routes.rb
# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :agent_runs, only: %i[create show], param: :public_id do
      post :cancel, on: :member
    end
    resources :calendar_events, path: "calendar/events", only: %i[create index update]
    get "data-explorer/accounts", to: "account_explorer#show", defaults: { format: :json }
    get "global-search", to: "global_search#show", defaults: { format: :json }
    get "relationship-explorer/accounts", to: "relationship_accounts#show", defaults: { format: :json }
    post "operator-chat/:room_id/messages", to: "operator_chat_messages#create", as: :operator_chat_messages
    post "operator-chat/:room_id/reset", to: "operator_chat_messages#reset", as: :operator_chat_reset
    resources :showcase_assets, only: %i[create destroy]
    resources :terminal_executions, only: :create, param: :id do
      post :cancel, on: :member
    end
    patch "workflow-items/:id/move", to: "workflow_items#move", as: :workflow_item_move
    resources :operations, only: %i[create show], param: :id do
      member do
        post :cancel
        post :retry
      end
    end
  end

  devise_for :admin_users, ActiveAdmin::Devise.config
  namespace :admin do
    get "analytics/data", to: "analytics_data#show", defaults: { format: :json }
  end
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: redirect("/admin")
end
