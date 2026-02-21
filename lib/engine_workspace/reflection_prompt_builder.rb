# frozen_string_literal: true

module CoEngineWorkspace
  # Composes a system prompt from manifest.json data. Replaces the per-engine
  # boilerplate that was previously hand-coded in each ChatController's
  # build_system_prompt method.
  #
  # Template sections:
  #   1. Role — from short_description + component_name
  #   2. Key concepts — from models (class names, table names, associations)
  #   3. API — from routes (resources, HTTP verbs)
  #   4. PEG — user and developer grammars if present
  #   5. Instructions footer — standard UI guidance
  class ReflectionPromptBuilder
    attr_reader :manifest

    def initialize(manifest)
      @manifest = manifest
    end

    def build
      parts = []
      parts << role_section
      parts << concepts_section if models.any?
      parts << api_section if routes_present?
      parts << peg_section
      parts << instructions_footer
      parts.compact.join("\n\n")
    end

    private

    def component_name
      manifest["component_name"] || manifest[:component_name] || "this engine"
    end

    def short_description
      manifest["short_description"] || manifest[:short_description]
    end

    def models
      manifest["models"] || manifest[:models] || []
    end

    def routes
      manifest["routes"] || manifest[:routes]
    end

    def peg_user
      manifest["peg_user"] || manifest[:peg_user]
    end

    def peg_developer
      manifest["peg_developer"] || manifest[:peg_developer]
    end

    def role_section
      name = component_name.sub(/^engine-/, "").tr("-", " ").capitalize
      desc = short_description.presence || "a component of the Ecosystems platform"
      "You are the #{name} assistant embedded in the Ecosystems platform.\n#{desc}"
    end

    def concepts_section
      lines = ["## Key Concepts", ""]
      models.each do |model|
        class_name = model["class_name"] || model[:class_name]
        table_name = model["table_name"] || model[:table_name]
        associations = model["associations"] || model[:associations] || []

        desc = "- **#{class_name}**"
        desc += " (table: `#{table_name}`)" if table_name.present?
        unless associations.empty?
          assoc_names = associations.map { |a| "#{a["type"] || a[:type]} #{a["name"] || a[:name]}" }
          desc += " — #{assoc_names.join(", ")}"
        end
        lines << desc
      end
      lines.join("\n")
    end

    def routes_present?
      return false unless routes

      entries = routes["entries"] || routes[:entries] || []
      entries.any?
    end

    def api_section
      entries = routes["entries"] || routes[:entries] || []
      lines = ["## API Endpoints", ""]

      entries.each do |entry|
        type = (entry["type"] || entry[:type]).to_s
        name = entry["name"] || entry[:name]

        case type
        when "resource"
          lines << "- `#{name}` — RESTful resource"
        when "get", "post", "put", "patch", "delete"
          lines << "- `#{type.upcase} #{name}`"
        when "namespace", "scope"
          lines << "- `#{name}/` (#{type})"
        end
      end

      lines.join("\n")
    end

    def peg_section
      parts = []
      if peg_user.present?
        parts << "--- External Interface (user.peg) ---"
        parts << peg_user
      end
      if peg_developer.present?
        parts << "--- Internal Implementation (developer.peg) ---"
        parts << peg_developer
      end
      parts.any? ? parts.join("\n\n") : nil
    end

    def instructions_footer
      <<~FOOTER.strip
        ## Instructions

        Always guide users to use the on-page UI controls rather than CLI commands or raw API calls.
        Only mention API endpoints or CLI if the user specifically asks for programmatic access.
        Be concise and helpful.
      FOOTER
    end
  end
end
