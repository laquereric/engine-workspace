# frozen_string_literal: true

module CoEngineWorkspace
  class Engine < ::Rails::Engine
    isolate_namespace CoEngineWorkspace
      include LibraryPlatform::AppendMigrations

    # Serve Stimulus controllers (accordion, chat, kanban) to the host app
    initializer "co_engine_workspace.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
      end
    end

    initializer "co_engine_workspace.assets" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
    end

    # Make the workspace layout available to all engines
    initializer "engine_workspace.view_paths" do
      ActiveSupport.on_load(:action_controller_base) do
        prepend_view_path CoEngineWorkspace::Engine.root.join("app", "views")
      end
    end

    # Include workspace helpers in all controllers
    initializer "engine_workspace.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper CoEngineWorkspace::WorkspaceHelper
      end
    end

    # Auto opt-in: set workspace layout and include Workspaceable for all
    # ActionController::Base subclasses. API controllers (ActionController::API)
    # are unaffected. Engines can opt out with explicit layout declaration.
    initializer "engine_workspace.default_layout" do
      ActiveSupport.on_load(:action_controller_base) do
        layout "co_engine_workspace/application"
        include CoEngineWorkspace::Workspaceable
      end
    end
  end
end
