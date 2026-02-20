# frozen_string_literal: true

module CoEngineWorkspace
  # Base class for all engine chat controllers.
  #
  # Consuming engines subclass and override hooks:
  #
  #   module EngineSwitch
  #     class ChatController < CoEngineWorkspace::ChatController
  #       def chat_model = "anthropic:claude-sonnet-4-5-20250929"
  #       def system_prompt = "You are the Switch engine assistant..."
  #     end
  #   end
  #
  class ChatController < ApplicationController
    include Workspaceable

    def create
      unless CoEngineWorkspace.llm_available?
        head :service_unavailable
        return
      end

      conversation = workspace_conversation
      user_message = params[:message]&.strip
      return head(:unprocessable_entity) if user_message.blank?

      conversation.transcript << { role: "user", content: user_message }

      begin
        response = conversation.chat_completion(openai: false)
        assistant_content = extract_content(response)
        conversation.transcript << { role: "assistant", content: assistant_content }
        conversation.save!
      rescue StandardError => e
        conversation.transcript << { role: "assistant", content: "Error: #{e.message}" }
        conversation.save!
      end

      respond_to do |format|
        format.turbo_stream { render_chat_stream(conversation) }
        format.html { redirect_back(fallback_location: "/") }
      end
    end

    private

    # Override in subclasses to change the LLM model
    def chat_model
      CoEngineWorkspace.default_model
    end

    # Override in subclasses to customize the system prompt
    def system_prompt
      workspace_system_prompt
    end

    # Override in subclasses to customize conversation scoping
    def conversation_scope_key
      "workspace:#{workspace_context[:engine]}:#{workspace_context[:controller]}"
    end

    # Override in subclasses to customize response extraction
    def extract_content(response)
      response.dig("choices", 0, "message", "content")
    end

    # Override in subclasses to customize the Turbo Stream response
    def render_chat_stream(conversation)
      render turbo_stream: turbo_stream.replace(
        "workspace-chat-messages",
        partial: "co_engine_workspace/chat_messages",
        locals: { conversation: conversation }
      )
    end
  end
end
