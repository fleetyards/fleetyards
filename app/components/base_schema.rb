# frozen_string_literal: true

class BaseSchema
  class_attribute :data_type_value
  class_attribute :properties_value, default: {}
  class_attribute :items_value
  class_attribute :required_value, default: []

  class << self
    def data_type(data_type)
      self.data_type_value = data_type
    end

    def property(prop_name, definition)
      self.properties_value = properties_value.merge(prop_name => definition)
    end

    def items(definition)
      self.items_value = definition
    end

    def required(prop_names)
      self.required_value = required_value + prop_names
    end
  end

  def to_schema
    raise "DataType is missing!" if data_type_value.blank?

    {
      type: data_type_value,
      properties: properties_value,
      items: items_value,
      required: required_value.presence,
      additionalProperties: false
    }.compact
  end
end
