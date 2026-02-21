# frozen_string_literal: true

module CoEngineWorkspace
  # Single controller for all bindable CRUD. The bindable name is a route
  # parameter — no per-bindable controllers needed.
  #
  # Routes map REST verbs to the six Bindable interface methods:
  #   GET    /:bindable_name          → list
  #   GET    /:bindable_name/:id      → read
  #   POST   /:bindable_name          → create
  #   PATCH  /:bindable_name/:id      → update
  #   DELETE /:bindable_name/:id      → delete
  #   POST   /:bindable_name/:id/execute → execute
  #
  class BindableController < ApplicationController
    include Workspaceable

    before_action :resolve_bindable
    before_action :set_record, only: %i[show edit update destroy execute]

    # GET /:bindable_name
    def index
      result = dispatch(:list, list_payload)
      @records = result.success? ? extract_list(result.value!) : []
      @columns = infer_columns(@records)
    end

    # GET /:bindable_name/:id
    def show; end

    # GET /:bindable_name/new
    def new
      @record = {}
    end

    # POST /:bindable_name
    def create
      result = dispatch(:create, create_payload)
      if result.success?
        record_id = result.value![:id] || result.value!["id"]
        redirect_to co_engine_workspace.bindable_record_path(@plural_name, record_id),
                    notice: "#{@bindable_name.titleize} created."
      else
        @record = create_payload
        flash.now[:alert] = result.failure[:message]
        render :new, status: :unprocessable_entity
      end
    end

    # GET /:bindable_name/:id/edit
    def edit; end

    # PATCH /:bindable_name/:id
    def update
      result = dispatch(:update, { id: params[:id], attrs: update_payload })
      if result.success?
        redirect_to co_engine_workspace.bindable_record_path(@plural_name, params[:id]),
                    notice: "#{@bindable_name.titleize} updated."
      else
        flash.now[:alert] = result.failure[:message]
        render :edit, status: :unprocessable_entity
      end
    end

    # DELETE /:bindable_name/:id
    def destroy
      result = dispatch(:delete, { id: params[:id] })
      if result.success?
        redirect_to co_engine_workspace.bindable_index_path(@plural_name),
                    notice: "#{@bindable_name.titleize} deleted."
      else
        redirect_to co_engine_workspace.bindable_record_path(@plural_name, params[:id]),
                    alert: result.failure[:message]
      end
    end

    # POST /:bindable_name/:id/execute
    def execute
      result = dispatch(:execute, { id: params[:id] }.merge(execute_payload))
      respond_to do |format|
        format.turbo_stream { handle_execute_turbo(result) }
        format.json { render json: result.success? ? result.value! : { error: result.failure }, status: result.success? ? :ok : :unprocessable_entity }
        format.html do
          redirect_to co_engine_workspace.bindable_record_path(@plural_name, params[:id]),
                      result.success? ? { notice: "Action completed." } : { alert: result.failure[:message] }
        end
      end
    end

    private

    # --- Bindable resolution ------------------------------------------------

    def resolve_bindable
      @plural_name    = params[:bindable_name]
      @bindable_name  = @plural_name.singularize
      @bindable_klass = self.class.lookup(@bindable_name)

      unless @bindable_klass
        raise ActionController::RoutingError, "No bindable found: #{@bindable_name}"
      end

      @bindable_instance = @bindable_klass.new
      # Derive engine context from the owning module
      @engine_name = @bindable_klass.module_parent.module_parent.name
                       .underscore.sub(/^engine_/, "")
      @bindables = self.class.bindables_for(@engine_name)
    end

    # Class-level lazy registry — scans loaded engines once, then caches.
    class << self
      def registry
        @registry || build_registry
      end

      def lookup(bindable_name)
        registry[:by_name][bindable_name]
      end

      def bindables_for(engine_name)
        registry[:by_engine][engine_name] || []
      end

      def reset_registry!
        @registry = nil
      end

      private

      def build_registry
        by_name   = {}
        by_engine = Hash.new { |h, k| h[k] = [] }

        ::Rails::Engine.subclasses.each do |engine_class|
          engine_mod = engine_class.module_parent
          next unless engine_mod && engine_mod != CoEngineWorkspace

          bindables_mod = "#{engine_mod}::Bindables".safe_constantize
          next unless bindables_mod

          engine_name = engine_mod.name.underscore.sub(/^engine_/, "")

          bindables_mod.constants.each do |const|
            klass = bindables_mod.const_get(const)
            next unless klass.is_a?(Class)
            next unless klass.included_modules.include?(LibraryBiological::Bindable)

            name = const.to_s.sub(/Bindable\z/, "").underscore
            by_name[name] = klass
            by_engine[engine_name] << name
          end
        end

        @registry = { by_name: by_name, by_engine: by_engine }
      end
    end

    # --- Dispatch -----------------------------------------------------------

    def dispatch(action, payload)
      context = LibraryBiological::ContextRecord.new(
        action: action,
        target: @bindable_klass.bindable_name,
        payload: payload
      )
      @bindable_instance.handle(context)
    end

    # --- Payload helpers ----------------------------------------------------

    def list_payload
      params.permit(:page, :per_page, :q, :status, :sort, :direction)
            .to_h.symbolize_keys
    end

    def create_payload
      params.fetch(@bindable_name, {}).permit!.to_h.symbolize_keys
    end

    def update_payload
      params.fetch(@bindable_name, {}).permit!.to_h.symbolize_keys
    end

    def execute_payload
      params.fetch(:execute, {}).permit!.to_h.symbolize_keys
    end

    # --- Record loading -----------------------------------------------------

    def set_record
      result = dispatch(:read, { id: params[:id] })
      if result.success?
        @record = result.value!
      else
        redirect_to co_engine_workspace.bindable_index_path(@plural_name),
                    alert: result.failure[:message]
      end
    end

    # --- Result helpers -----------------------------------------------------

    def extract_list(value)
      case value
      when Hash  then Array(value[:records] || value["records"] || value.values.first)
      when Array then value
      else            [value]
      end
    end

    def handle_execute_turbo(result)
      if result.success?
        set_record # refresh
        render turbo_stream: turbo_stream.replace(
          "bindable-record-#{params[:id]}",
          partial: "co_engine_workspace/bindable/record",
          locals: { record: @record, bindable_name: @bindable_name }
        )
      else
        head :unprocessable_entity
      end
    end

    def infer_columns(records)
      return [] if records.empty?

      sample = records.first
      keys = (sample.is_a?(Hash) ? sample.keys : sample.try(:attributes)&.keys || [])
      keys.map(&:to_sym).reject { |k| k == :id }.map do |k|
        { key: k, label: k.to_s.titleize }
      end
    end
  end
end
