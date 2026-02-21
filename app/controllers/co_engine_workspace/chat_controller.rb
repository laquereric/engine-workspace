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
    before_action :set_nav_context, only: :index

    def index; end

    def create
      unless CoEngineWorkspace.llm_available?
        head :service_unavailable
        return
      end

      conversation = workspace_conversation
      user_message = params[:message]&.strip
      return head(:unprocessable_entity) if user_message.blank?

      # Read transcript directly from DB — Raix adapter is in-memory only
      messages = read_transcript(conversation)
      messages << { "role" => "user", "content" => user_message }

      begin
        response = conversation.send(:ruby_llm_request,
          params: {},
          model: conversation.model || chat_model,
          messages: messages)
        assistant_content = extract_content(response)
        messages << { "role" => "assistant", "content" => assistant_content }
      rescue StandardError => e
        messages << { "role" => "assistant", "content" => "Error: #{e.message}" }
      end

      save_transcript(conversation, messages)

      respond_to do |format|
        format.turbo_stream { render_chat_stream(conversation, messages) }
        format.html { redirect_back(fallback_location: "/") }
      end
    end

    private

    def set_nav_context
      registry = CoEngineWorkspace::BindableController.registry
      @bindables = registry[:by_name].keys
      @engine_name = registry[:by_engine].keys.first&.titleize || "Workspace"
    end

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

    # Read transcript as plain array from DB, bypassing Raix adapter.
    # Handles double-encoded JSON (serialize + manual to_json).
    def read_transcript(conversation)
      raw = conversation.read_attribute_before_type_cast("transcript") || "[]"
      result = JSON.parse(raw)
      result = JSON.parse(result) if result.is_a?(String)
      Array(result)
    end

    # Write transcript array directly to DB, bypassing Raix adapter.
    def save_transcript(conversation, messages)
      conversation.update_column(:transcript, JSON.dump(messages))
    end

    # Override in subclasses to customize the Turbo Stream response
    def render_chat_stream(_conversation, messages)
      render turbo_stream: turbo_stream.replace(
        "workspace-chat-messages",
        partial: "co_engine_workspace/chat_messages",
        locals: { messages: messages }
      )
    end
  end
end
