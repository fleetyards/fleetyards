# frozen_string_literal: true

class ApiValidationError < Committee::ValidationError
  def error_body
    {
      code: id,
      message: message
    }
  end

  def render
    [
      status,
      {"Content-Type" => "application/json"},
      [JSON.generate(error_body)]
    ]
  end
end
