# frozen_string_literal: true

class ComponentsLoader
  attr_accessor :identifier, :type

  def initialize(identifier: nil)
    @identifier = identifier
  end

  def schemas(identifier)
    @identifier = identifier
    @type = "schemas"

    load_components
  end

  private def load_components
    load_classes.map do |klass|
      {extract_component_name(klass) => klass.new.to_schema.merge(title: extract_component_name(klass))}
    end.reduce(:merge)
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
    klass.to_s.remove(definitions_path.camelize)
  end

  private def definitions_path
    "#{identifier}/#{type}"
  end

  private def base_path
    @base_path ||= Rails.root.join("app/components")
  end
end
