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

    def workspace_tasks_badge
      return nil unless CoEngineWorkspace.planner_available?

      assertions = workspace_assertions rescue []
      proposed_count = assertions.count { |a| a.status == "proposed" }
      proposed_count > 0 ? proposed_count : nil
    end
  end
end
