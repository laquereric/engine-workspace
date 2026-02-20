# frozen_string_literal: true

module EngineWorkspace
  class Engine < ::Rails::Engine
    isolate_namespace EngineWorkspace
      include LibraryPlatform::AppendMigrations

    # Make the workspace layout available to all engines
    initializer "engine_workspace.view_paths" do
      ActiveSupport.on_load(:action_controller_base) do
        prepend_view_path EngineWorkspace::Engine.root.join("app", "views")
      end
    end

    # Include workspace helpers in all controllers
    initializer "engine_workspace.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper EngineWorkspace::WorkspaceHelper
      end
    end

    # Auto opt-in: set workspace layout and include Workspaceable for all
    # ActionController::Base subclasses. API controllers (ActionController::API)
    # are unaffected. Engines can opt out with explicit layout declaration.
    initializer "engine_workspace.default_layout" do
      ActiveSupport.on_load(:action_controller_base) do
        layout "engine_workspace/application"
        include EngineWorkspace::Workspaceable
      end
    end
  end
end
