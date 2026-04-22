# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Queries
        class ModelHardpointLoadoutQuery
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelHardpointIdEq: {type: :string, format: :uuid},
              nameCont: {type: :string}
            },
            additionalProperties: false,
            example: {}
          })
        end
      end
    end
  end
end
