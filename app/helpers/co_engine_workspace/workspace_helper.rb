# frozen_string_literal: true

module CoEngineWorkspace
  module WorkspaceHelper
    def workspace_chat_badge
      return nil unless CoEngineWorkspace.llm_available?

      conversation = workspace_conversation rescue nil
      return nil unless conversation

      unread = conversation.transcript.count { |m| m["role"] == "assistant" || m[:role] == "assistant" }
      unread > 0 ? unread : nil
    end

    # Workspace aliases — delegate to design system helpers
    def ws_nav_bar(...)          = ds_nav_bar(...)
    def ws_bindable_list(...)    = ds_bindable_list(...)
    def ws_bindable_detail(...)  = ds_bindable_detail(...)
    def ws_bindable_counts(...)  = ds_bindable_counts(...)
  end
end
