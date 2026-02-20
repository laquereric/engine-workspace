# frozen_string_literal: true

module EngineWorkspace
  # Lightweight line-by-line parser for .peg reflection files.
  # Extracts header fields, named sections, and PEG rules for display.
  # NOT a full PEG evaluator — structural extraction only.
  class PegParser
    Section = Struct.new(:name, :rules, keyword_init: true)
    Rule = Struct.new(:name, :definition, keyword_init: true)
    PegData = Struct.new(:component, :type, :namespace, :sections, keyword_init: true)

    HEADER_RE  = /\A#\s+(\w[\w\s]*\w):\s+(.+)\z/
    SECTION_RE = /\A#\s+───\s+(.+?)\s+───/
    RULE_RE    = /\A(\w+)\s+<-\s+(.*)\z/
    SKIP_SECTIONS = %w[Terminals].freeze

    def self.parse(content)
      new(content).parse
    end

    def initialize(content)
      @lines = (content || "").lines.map(&:rstrip)
    end

    def parse
      headers = {}
      sections = []
      current_section = nil

      @lines.each do |line|
        case line
        when HEADER_RE
          headers[Regexp.last_match(1).strip] = Regexp.last_match(2).strip
        when SECTION_RE
          section_name = Regexp.last_match(1).strip
          # Remove trailing decorative dashes
          section_name = section_name.sub(/\s*─+\z/, "").strip
          if SKIP_SECTIONS.include?(section_name)
            current_section = nil
          else
            current_section = Section.new(name: section_name, rules: [])
            sections << current_section
          end
        when RULE_RE
          next unless current_section

          current_section.rules << Rule.new(
            name: Regexp.last_match(1).strip,
            definition: Regexp.last_match(2).strip
          )
        end
      end

      PegData.new(
        component: headers["Component"],
        type:      headers["Type"],
        namespace: headers["Namespace"],
        sections:  sections
      )
    end
  end
end
