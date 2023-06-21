# frozen_string_literal: true

class ComponentsLoader
  attr_accessor :identifier, :type

  VALID_TYPES = %w[
    schemas parameters securitySchemes requestBodies responses headers examples links callbacks
  ].freeze

  def initialize(identifier)
    @identifier = identifier
  end

  VALID_TYPES.each do |type|
    define_method(type) do
      @type = type

      load_components
    end
  end

  private def load_components
    components = {}

    load_classes.each do |klass|
      component_name = extract_component_name(klass)

      definition = klass.new.to_schema

      if components[component_name].present?
        raise "Duplicate component name \"#{component_name}\" found in \"#{identifier}/#{type}\""
      end

      components[component_name] = definition.merge(title: component_name)
    end

    components
  end

  private def load_classes
    Dir.glob(base_path.join("#{definitions_path}/**/*")).filter_map do |file_path|
      next if File.directory?(file_path)

      file_path.gsub(base_path.to_s, "") # remove base_path
        .gsub(".rb", "") # remove extension
        .camelize.constantize
    end
  end

  private def extract_component_name(klass)
    klass_name = extract_class_name(klass)

    klass_name_parts = klass_name.split("::").reject(&:blank?)

    klass_name_parts.join
  end

  private def extract_class_name(klass)
    klass.name.split("::").last
  end

  private def definitions_path
    "#{identifier}/#{type}"
  end

  private def base_path
    @base_path ||= Rails.root.join("app/api_components")
  end
end
