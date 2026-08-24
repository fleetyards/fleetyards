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
              # Nullable because clearing the field is how a picture is
              # removed -- the file input emits a null -- and a plain string
              # made that request a 400.
              logo: {type: [:string, :null]},
              icon: {type: [:string, :null]},
              scRef: {type: :string}
            },
            additionalProperties: false
          })
        end
      end
    end
  end
end
