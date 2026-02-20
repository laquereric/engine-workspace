# frozen_string_literal: true

EngineWorkspace::Engine.routes.draw do
  # Chat message submission (Turbo Stream)
  post "chat/messages", to: "chat#create", as: :chat_messages

  # Kanban assertion status updates
  patch "kanban/assertions/:id", to: "kanban#update", as: :kanban_assertion
end
