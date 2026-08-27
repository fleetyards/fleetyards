# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelHullPart
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            health: {type: :number},
            category: {"$ref": "#/components/schemas/ModelHullPartCategoryEnum"}
          },
          required: %w[name health category],
          additionalProperties: false

        })
      end
    end
  end
end
