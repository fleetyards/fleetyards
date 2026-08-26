# frozen_string_literal: true

module V1
  module Schemas
    class SuccessResponse
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          success: {type: :boolean}
        }
      })
    end
  end
end
