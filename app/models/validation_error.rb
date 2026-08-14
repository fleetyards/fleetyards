# frozen_string_literal: true

class ValidationError
  attr_accessor :code, :message, :errors

  def initialize(code, message: nil, errors: nil)
    self.code = "validation_error.#{code}"
    self.message = message || I18n.t(:"validation_error.#{code}")
    self.errors = transform_errors(errors) if errors.present?
  end

  def as_json(*)
    {
      code: code,
      message: message,
      errors: errors&.map { |field_error| field_error.merge(attribute: camelize(field_error[:attribute])) }
    }.compact
  end

  private def transform_errors(errors)
    errors_list = errors.is_a?(Array) ? errors : [errors]
    errors_list.flat_map(&:errors)
      .group_by(&:attribute)
      .map do |attribute, attribute_errors|
        {
          attribute: attribute,
          messages: attribute_errors.map { |error| {code: error.type, message: error.full_message} }.uniq
        }
      end
  end

  # Matches the key casing of every other response: Jbuilder is configured with
  # `key_format camelize: :lower`, and inbound params are decamelized again by
  # Middleware::TransformParameters.
  private def camelize(attribute)
    attribute.to_s.camelize(:lower)
  end
end
