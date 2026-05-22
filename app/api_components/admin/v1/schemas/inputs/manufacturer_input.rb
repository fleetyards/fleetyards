# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Inputs
        class ManufacturerInput
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: :string},
              longName: {type: :string},
              code: {type: :string},
              description: {type: :string},
              knownFor: {type: :string},
              logo: {type: :string},
              scRef: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
