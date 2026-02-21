# frozen_string_literal: true

module CoEngineWorkspace
  module Workspaceable
    extend ActiveSupport::Concern

    included do
      before_action :set_workspace_context
      before_action :load_peg_data
      helper_method :workspace_conversation, :workspace_context, :workspace_engine_name
    end

    private

    def set_workspace_context
      @workspace_context = {
        engine: self.class.module_parent_name,
        controller: controller_name,
        action: action_name,
        record_id: params[:id]
      }
      @engine_name ||= workspace_engine_name
      @bindables   ||= []
    end

    def workspace_engine_name
      self.class.module_parent_name&.underscore&.sub(/^engine_/, "")
    end

    def workspace_context
      @workspace_context || {}
    end

    def load_peg_data
      engine_module = workspace_context[:engine]
      return unless engine_module

      user_content = CoEngineWorkspace::EnginePathResolver.peg_file(engine_module, "user.peg")
      dev_content  = CoEngineWorkspace::EnginePathResolver.peg_file(engine_module, "developer.peg")

      @peg_user      = user_content ? CoEngineWorkspace::PegParser.parse(user_content) : nil
      @peg_developer = dev_content  ? CoEngineWorkspace::PegParser.parse(dev_content) : nil
      @peg_user_raw      = user_content
      @peg_developer_raw = dev_content
    rescue StandardError
      @peg_user = nil
      @peg_developer = nil
      @peg_user_raw = nil
      @peg_developer_raw = nil
    end

    def workspace_conversation
      return nil unless CoEngineWorkspace.llm_available?

      @workspace_conversation ||= begin
        scope_key = respond_to?(:conversation_scope_key, true) ? conversation_scope_key : default_scope_key
        conversation = EngineLlm::Conversation.find_or_initialize_by(title: scope_key)
        if conversation.new_record?
          prompt = respond_to?(:system_prompt, true) ? system_prompt : workspace_system_prompt
          model  = respond_to?(:chat_model, true) ? chat_model : CoEngineWorkspace.default_model
          conversation.transcript = [{ role: "system", content: prompt }]
          conversation.model = model
          conversation.save!
        end
        conversation
      end
    end

    def default_scope_key
      "workspace:#{workspace_context[:engine]}:#{workspace_context[:controller]}"
    end

    def workspace_system_prompt
      reflection_prompt = build_prompt_from_reflection
      if reflection_prompt
        dynamic = dynamic_prompt_context
        return [reflection_prompt, dynamic].compact.join("\n\n")
      end

      # Fallback: PEG-only prompt when no manifest.json exists
      ctx = workspace_context
      parts = []
      parts << "You are a workspace assistant for the #{ctx[:engine]} engine."
      parts << "The user is currently on the #{ctx[:controller]}##{ctx[:action]} page#{ctx[:record_id] ? " viewing record ##{ctx[:record_id]}" : ""}."

      if @peg_user_raw.present?
        parts << ""
        parts << "--- External Interface (user.peg) ---"
        parts << @peg_user_raw
      end

      if @peg_developer_raw.present?
        parts << ""
        parts << "--- Internal Implementation (developer.peg) ---"
        parts << @peg_developer_raw
      end

      parts << ""
      parts << "Help the user understand this engine's architecture, models, routes, and dependencies. Be concise and helpful."

      parts.join("\n")
    end

    # Acquires prompt through the engine-platform Reflection Bindable.
    # Composes in-memory from manifest.json — no flat file needed.
    def build_prompt_from_reflection
      engine_module = workspace_context[:engine]
      return nil unless engine_module
      return nil unless defined?(EnginePlatform::Reflection)

      context = LibraryBiological::ContextRecord.new(
        action: :execute,
        target: "reflection",
        payload: { operation: "prompt", module_name: engine_module }
      )
      result = EnginePlatform::Reflection.new.handle(context)
      result[:prompt] if result.is_a?(Hash) && result[:prompt]
    rescue StandardError
      nil
    end

    # Hook for engines to inject dynamic state into the system prompt.
    # Override in subclasses to add live context (e.g. container status, service health).
    # Returns a string or nil.
    def dynamic_prompt_context
      nil
    end
  end
end
