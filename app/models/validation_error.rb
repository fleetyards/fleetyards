# frozen_string_literal: true

class ValidationError
  attr_accessor :code, :message, :errors

  def initialize(code, message: nil, errors: nil)
    self.code = "validation_error.#{code}"
    self.message = message || I18n.t(:"validation_error.#{code}")
    self.errors = transform_errors(errors) if errors.present?
  end

  private def transform_errors(errors)
    errors.keys.map do |key|
      {
        attribute: key,
        messages: errors[key].map do |error|
          {
            code: error.type,
            message: error.full_message
          }
        end
      }
    end
  end
end
