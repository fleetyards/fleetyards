# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ConfirmAccessInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            password: {type: :string}
          },
          additionalProperties: false,
          required: %w[password]
        })
      end
    end
  end
end
