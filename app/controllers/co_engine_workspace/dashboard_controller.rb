# frozen_string_literal: true

module CoEngineWorkspace
  class DashboardController < ApplicationController
    include Workspaceable
    before_action :set_dashboard_context

    def index
      @bindable_counts = build_bindable_counts
    end

    private

    def set_dashboard_context
      registry = CoEngineWorkspace::BindableController.registry
      @bindables = registry[:by_name].keys
      @engine_name = registry[:by_engine].keys.first&.titleize || "Workspace"
    end

    def build_bindable_counts
      registry = CoEngineWorkspace::BindableController.registry
      registry[:by_name].map do |name, klass|
        count = fetch_count(klass)
        plural = name.pluralize
        {
          label: name.titleize.pluralize,
          count: count,
          href: co_engine_workspace.bindable_index_path(plural)
        }
      end
    end

    def fetch_count(klass)
      instance = klass.new
      context = LibraryBiological::ContextRecord.new(
        action: :list,
        target: klass.bindable_name,
        payload: {}
      )
      result = instance.handle(context)
      return 0 unless result.success?

      value = result.value!
      case value
      when Hash then Array(value[:records] || value["records"] || value.values.first).size
      when Array then value.size
      else 1
      end
    rescue StandardError
      0
    end
  end
end
