# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ImportInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            import: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
