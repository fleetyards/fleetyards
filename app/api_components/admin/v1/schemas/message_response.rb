# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class MessageResponse
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            message: {type: :string}
          },
          required: [:message]
        })
      end
    end
  end
end
