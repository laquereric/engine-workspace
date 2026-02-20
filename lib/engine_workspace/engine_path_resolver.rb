# frozen_string_literal: true

module CoEngineWorkspace
  # Resolves an engine module name (e.g. "EngineSwitch") to its filesystem root
  # via Rails::Engine.root, then provides helpers to read reflection files.
  class EnginePathResolver
    class << self
      # Returns the engine root path for a given module name string.
      # Tries direct constantize first, then scans Engine subclasses.
      def resolve(module_name)
        engine_class = find_engine_class(module_name)
        engine_class&.root&.to_s
      end

      # Reads a PEG file from doc/reflection/ for the given engine module.
      def peg_file(module_name, filename)
        root = resolve(module_name)
        return nil unless root

        path = File.join(root, "doc", "reflection", filename)
        File.exist?(path) ? File.read(path) : nil
      end

      private

      def find_engine_class(module_name)
        # Try direct: "EngineSwitch::Engine"
        klass = "#{module_name}::Engine".safe_constantize
        return klass if klass && klass < ::Rails::Engine

        # Fallback: scan subclasses for matching namespace
        ::Rails::Engine.subclasses.find do |engine|
          engine.module_parent_name == module_name
        end
      end
    end
  end
end
