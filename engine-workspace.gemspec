# frozen_string_literal: true

require_relative "lib/engine_workspace/version"

Gem::Specification.new do |spec|
  spec.name        = "engine-workspace"
  spec.version     = CoEngineWorkspace::VERSION
  spec.authors     = ["Eric Laquer"]
  spec.email       = ["LaquerEric@gmail.com"]

  spec.summary     = "Workspace layout engine — nav bar, chat IO, and bindable CRUD"
  spec.description = "Rails engine providing per-page workspace layout with navigation, " \
                     "an AI chat panel (engine-llm), and generic bindable CRUD for any " \
                     "engine that registers biological-IT Bindables."
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
