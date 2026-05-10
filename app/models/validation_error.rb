# frozen_string_literal: true

class ValidationError
  attr_accessor :code, :message, :errors

  def initialize(code, message: nil, errors: nil)
    self.code = "validation_error.#{code}"
    self.message = message || I18n.t(:"validation_error.#{code}")
    self.errors = transform_errors(errors) if errors.present?
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
end
