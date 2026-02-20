# frozen_string_literal: true

module EngineWorkspace
  class KanbanController < ApplicationController
    include Workspaceable

    def update
      unless EngineWorkspace.planner_available?
        head :service_unavailable
        return
      end

      assertion = Planner::Assertion.find(params[:id])
      if assertion.update(assertion_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "workspace-kanban-board",
              partial: "engine_workspace/kanban_board",
              locals: { assertions: workspace_assertions }
            )
          end
          format.html { redirect_back(fallback_location: "/") }
        end
      else
        head :unprocessable_entity
      end
    end

    private

    def assertion_params
      params.require(:assertion).permit(:status)
    end
  end
end
