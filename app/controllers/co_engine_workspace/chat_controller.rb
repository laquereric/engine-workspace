# frozen_string_literal: true

module CoEngineWorkspace
  # Base class for all engine chat controllers.
  #
  # Consuming engines subclass and override hooks:
  #
  #   module EngineSwitch
  #     class ChatController < CoEngineWorkspace::ChatController
  #       def build_system_prompt = "You are the Switch engine assistant..."
  #       def chat_welcome_data = { intro: "...", items: [...], outro: "..." }
  #     end
  #   end
  #
  # Override hooks:
  #   build_system_prompt  — system prompt for the LLM
  #   chat_welcome_data    — welcome card content { intro:, items: [...], outro: }
  #   conversation_title   — conversation scope key (default: derived from module name)
  #   set_nav_context      — set @engine_name and @bindables for nav bar
  #
  class ChatController < ApplicationController
    include Workspaceable
    skip_forgery_protection only: :chat
    before_action :set_nav_context, only: :index

    def index
      welcome = chat_welcome_data
      @chat_welcome_items = welcome.delete(:items) || []
      @chat_welcome = welcome
    end

    def chat
      user_content = params[:message].to_s.strip
      if user_content.blank?
        return render json: { error: "Message cannot be blank" }, status: :unprocessable_entity
      end

      unless llm_available?
        return render json: { error: "LLM engine is not available" }, status: :service_unavailable
      end

      conversation = find_or_create_conversation

      messages = conversation.read_attribute(:transcript) || []
      messages = [{ "role" => "system", "content" => build_system_prompt }] + messages.reject { |m| m["role"] == "system" }
      messages << { "role" => "user", "content" => user_content }

      begin
        conversation.transcript.clear
        messages.each { |msg| conversation.transcript << msg }

        response = conversation.chat_completion(
          params: { temperature: 0.7, max_tokens: 2048 }
        )
        content = extract_content(response) || response.to_s
        messages << { "role" => "assistant", "content" => content }
      rescue => e
        Rails.logger.error("[Workspace Chat] chat_completion failed: #{e.class}: #{e.message}")
        content = "I'm sorry, I encountered an error processing your request."
        messages << { "role" => "assistant", "content" => content }
      end

      conversation.write_attribute(:transcript, messages)
      conversation.save!

      render json: { role: "assistant", content: content, conversation_id: conversation.id }
    end

    private

    def llm_available?
      defined?(EngineLlm::Conversation)
    end

    def find_or_create_conversation
      model = resolve_model
      title = conversation_title

      conversation = EngineLlm::Conversation.find_by(title: title)
      unless conversation
        conversation = EngineLlm::Conversation.create!(
          title: title,
          transcript: []
        )
      end

      conversation.model = model if model.present?
      conversation
    end

    # Override to change conversation scope. Default derives from engine module.
    # e.g. EngineContext::ChatController → "engine_context:chat"
    def conversation_title
      self.class.module_parent_name.underscore.tr("/", ":") + ":chat"
    end

    def resolve_model
      if defined?(EngineLlm::Preference)
        pref = EngineLlm::Preference.instance
        pref.model_value || EngineLlm::Setting.get("model")
      end
    end

    # Override to customize the system prompt for the LLM.
    def build_system_prompt
      "You are a helpful assistant."
    end

    # Override to customize the welcome card content.
    def chat_welcome_data
      { intro: "How can I help you today?", items: [], outro: "" }
    end

    # Override to set @engine_name and @bindables for the nav bar.
    def set_nav_context
      @engine_name = self.class.module_parent_name.demodulize.sub(/\AEngine/, "")
      @bindables = []
    end

    def extract_content(response)
      return response if response.is_a?(String)
      return response.dig("choices", 0, "message", "content") if response.is_a?(Hash)

      nil
    end
  end
end
