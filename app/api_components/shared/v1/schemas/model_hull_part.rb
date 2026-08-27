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
            category: ::Shared::V1::Schemas::Enums::ModelHullPartCategoryEnum
          },
          required: %w[name health category],
          additionalProperties: false

        })
      end
    end
  end
end
