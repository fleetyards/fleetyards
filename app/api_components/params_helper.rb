class ParamsHelper
  attr_accessor :schema

  def initialize(schema_path)
    @schema = load_schema(schema_path)
  end

  def to_params(input_type)
    extract_type(input_type).dig("properties").map do |key, value|
      extract_params(key, value)
    end.flatten
  end

  private def extract_params(key, value)
    if value["$ref"].present?
      ref_value = extract_type(value["$ref"])
      if ref_value.present?
        extract_params(key, ref_value)
      else
        transform_key(key)
      end
    elsif value["anyOf"].present?
      value["anyOf"].map do |option|
        extract_params(key, option)
      end.flatten
    elsif value["oneOf"].present?
      extract_params(key, value["oneOf"].first)
    elsif value["type"] == "object"
      if value["properties"].present?
        {transform_key(key) => value["properties"].transform_keys { |k| transform_key(k) }}
      else
        transform_key(key)
      end
    elsif value["type"] == "array"
      {transform_key(key) => []}
    else
      transform_key(key)
    end
  end

  private def transform_key(key)
    key.to_s.underscore.to_sym
  end

  private def load_schema(schema_path)
    YAML.load_file(Rails.root.join(Rswag::Api.config.openapi_root, schema_path))
  end

  private def extract_type(type)
    prefix = if type.starts_with?("#/components/schemas/")
      "components/schemas/"
    elsif type.starts_with?("#/components/parameters/")
      "components/parameters/"
    else
      "components/schemas/"
    end

    typepath = "#{prefix}#{type}".split("/")

    schema.dig(*typepath)
  end
end
