# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ConfirmAccessEmailInput
        include Rswag::SchemaComponents::Component

        schema({
          type: :object,
          properties: {
            redirectPath: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
