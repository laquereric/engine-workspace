# frozen_string_literal: true

require "engine_workspace/version"
require "engine_workspace/peg_parser"
require "engine_workspace/engine_path_resolver"
require "engine_workspace/engine" if defined?(Rails)

module CoEngineWorkspace
  mattr_accessor :default_model, default: "ollama:command-r"

  class << self
    def llm_available?
      defined?(EngineLlm)
    end

    def planner_available?
      defined?(Planner)
    end
  end
end
