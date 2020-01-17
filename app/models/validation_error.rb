# frozen_string_literal: true

class ValidationError
  attr_accessor :code, :message, :errors

  def initialize(code, errors = {}, message = nil)
    self.code = "validation_error.#{code}"
    self.message = message || I18n.t(:"validation_error.#{code}")
    self.errors = errors if errors.present?
  end
end
