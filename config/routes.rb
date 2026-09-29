# config/routes.rb
# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  namespace :admin do
    if Conversations::Availability.enabled?
      get "conversations/search", to: "conversations#search", as: :conversation_search
      scope "conversations/:conversation_public_id", as: :conversation do
        resources :messages,
                  controller: "conversation_messages",
                  only: %i[create edit index],
                  param: :message_public_id
        resources :scheduled_messages,
                  controller: "conversation_scheduled_messages",
                  only: %i[create destroy edit index update],
                  param: :scheduled_message_public_id
        patch "messages/:message_public_id",
              to: "conversation_messages#update",
              as: :message
        delete "messages/:message_public_id",
               to: "conversation_messages#destroy",
               as: :withdraw_message
        match "messages/:message_public_id/saved",
              to: "conversation_saved_messages#update",
              via: %i[delete post],
              as: :saved_message
        post "read-state/:message_public_id",
             to: "conversation_read_states#create",
             as: :read_state
        delete "read-state/:message_public_id",
               to: "conversation_read_states#destroy",
               as: :unread_state
      end
    end
    patch "privacy-view", to: "privacy_views#update", as: :privacy_view
    resources :activity_center_notifications,
              path: "activity-center/notifications",
              controller: "activity_center_notifications",
              only: %i[create index update]
    resources :agent_runs, only: %i[create show], param: :public_id do
      post :cancel, on: :member
    end
    get "audit-profiles/:id/history", to: "audit_histories#show", as: :audit_profile_history
    resources :calendar_events, path: "calendar/events", only: %i[create index update]
    patch "content-builder/documents/:id", to: "content_builder_documents#update", as: :content_builder_document
    resources :csv_import_workflow_imports,
              path: "csv-imports",
              controller: "bulk_csv_imports",
              only: %i[create show],
              param: :token do
      post :confirm, on: :member
    end
    get "data-explorer/accounts", to: "account_explorer#show", defaults: { format: :json }
    get "global-search", to: "global_search#show", defaults: { format: :json }
    get "geospatial/locations", to: "geospatial_locations#index", defaults: { format: :json }
    resources :hierarchy_nodes, controller: "hierarchy_explorer_nodes", only: %i[index update]
    resources :image_annotations, controller: "image_editor_annotations", only: :update
    patch "inline-edit/accounts/:id", to: "inline_account_fields#update", as: :inline_account_field
    patch "material-studio/configurations/:id",
          to: "material_sphere_configurations#update",
          as: :material_sphere_configuration
    resources :onboarding_drafts, controller: "wizard_drafts", only: :update
    get "relationship-explorer/accounts", to: "relationship_accounts#show", defaults: { format: :json }
    get "social-graph", to: "social_graph#show", defaults: { format: :json }
    patch "theme-preference", to: "theme_preferences#update", as: :theme_preference
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
