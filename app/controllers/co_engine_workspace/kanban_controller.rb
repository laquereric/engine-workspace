# frozen_string_literal: true

module CoEngineWorkspace
  # Base class for all engine kanban controllers.
  #
  # Consuming engines subclass and override hooks:
  #
  #   module EnginePlanner
  #     class KanbanController < CoEngineWorkspace::KanbanController
  #       def permitted_statuses = %w[proposed accepted rejected]
  #     end
  #   end
  #
  class KanbanController < ApplicationController
    include Workspaceable

    def update
      unless CoEngineWorkspace.planner_available?
        head :service_unavailable
        return
      end

      assertion = find_assertion
      if assertion.update(assertion_params)
        respond_to do |format|
          format.turbo_stream { render_kanban_stream }
          format.html { redirect_back(fallback_location: "/") }
        end
      else
        head :unprocessable_entity
      end
    end

    private

    # Override in subclasses to customize assertion lookup
    def find_assertion
      Planner::Assertion.find(params[:id])
    end

    # Override in subclasses to restrict allowed statuses
    def assertion_params
      params.require(:assertion).permit(:status)
    end

    # Override in subclasses to customize the Turbo Stream response
    def render_kanban_stream
      render turbo_stream: turbo_stream.replace(
        "workspace-kanban-board",
        partial: "co_engine_workspace/kanban_board",
        locals: { assertions: workspace_assertions }
      )
    end
  end
end
