# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SyncRsiHangarInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            items: {
              type: :array,
              items: {"$ref": "#/components/schemas/RsiHangarItemInput"}
            }
          }
        })
      end
    end
  end
end
