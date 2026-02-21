# frozen_string_literal: true

CoEngineWorkspace::Engine.routes.draw do
  # Chat message submission (Turbo Stream)
  post "chat/messages", to: "chat#create", as: :chat_messages

  # Full-page views (must precede the :bindable_name catch-all)
  get "chat",      to: "chat#index",      as: :chat
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Bindable CRUD — :bindable_name is the pluralized resource name (e.g. "plans", "sources")
  get    ":bindable_name",              to: "bindable#index",   as: :bindable_index
  get    ":bindable_name/new",          to: "bindable#new",     as: :bindable_new
  post   ":bindable_name",              to: "bindable#create",  as: :bindable_create
  get    ":bindable_name/:id",          to: "bindable#show",    as: :bindable_record
  get    ":bindable_name/:id/edit",     to: "bindable#edit",    as: :bindable_edit
  patch  ":bindable_name/:id",          to: "bindable#update",  as: :bindable_update
  delete ":bindable_name/:id",          to: "bindable#destroy", as: :bindable_destroy
  post   ":bindable_name/:id/execute",  to: "bindable#execute", as: :bindable_execute
end
