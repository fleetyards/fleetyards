# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Options
        class ModelOptions < Shared::V1::Schemas::BaseList
          include OpenapiRuby::Components::Base

          schema({
            properties: {
              items: {type: :array, items: {"$ref": "#/components/schemas/ModelOption"}}
            },
            required: %w[items]
          })
        end
      end
    end
  end
end
