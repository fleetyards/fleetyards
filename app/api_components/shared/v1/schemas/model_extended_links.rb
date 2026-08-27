# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # ModelExtended used to merge self and frontend into the links it
      # inherited from Model. A $ref cannot be merged into, so the extended
      # variant spells out all four.
      class ModelExtendedLinks
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            salesPageUrl: {type: :string},
            storeUrl: {type: :string},
            self: {type: :string, format: :uri},
            frontend: {type: :string, format: :uri}
          },
          additionalProperties: false
        })
      end
    end
  end
end
