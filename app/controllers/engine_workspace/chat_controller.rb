# frozen_string_literal: true

module EngineWorkspace
  class ChatController < ApplicationController
    include Workspaceable

    def create
      unless EngineWorkspace.llm_available?
        head :service_unavailable
        return
      end

      conversation = workspace_conversation
      user_message = params[:message]&.strip
      return head(:unprocessable_entity) if user_message.blank?

      conversation.transcript << { role: "user", content: user_message }

      begin
        response = conversation.chat_completion(openai: false)
        assistant_content = response.dig("choices", 0, "message", "content")
        conversation.transcript << { role: "assistant", content: assistant_content }
        conversation.save!
      rescue StandardError => e
        conversation.transcript << { role: "assistant", content: "Error: #{e.message}" }
        conversation.save!
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "workspace-chat-messages",
            partial: "engine_workspace/chat_messages",
            locals: { conversation: conversation }
          )
        end
        format.html { redirect_back(fallback_location: "/") }
      end
    end
  end
end
