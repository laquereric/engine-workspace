# frozen_string_literal: true

require_relative "lib/engine_workspace/version"

Gem::Specification.new do |spec|
  spec.name        = "engine-workspace"
  spec.version     = EngineWorkspace::VERSION
  spec.authors     = ["Eric Laquer"]
  spec.email       = ["LaquerEric@gmail.com"]

  spec.summary     = "Workspace layout engine — accordion-based page + chat + kanban shell"
  spec.description = "Rails engine providing a three-panel accordion workspace layout that " \
                     "composes an engine's page view, an AI chat panel (engine-llm), and a " \
                     "task kanban panel (engine-planner) into a unified workspace experience."
  spec.homepage    = "https://github.com/laquereric/engine-workspace"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/laquereric/engine-workspace"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,db,lib}/**/*", "README.md", "LICENSE.txt"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0", "< 9.0"
  spec.add_dependency "engine-design-system"
  spec.add_dependency "view_component"
end
