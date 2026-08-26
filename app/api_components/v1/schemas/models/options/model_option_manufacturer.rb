# frozen_string_literal: true

module V1
  module Schemas
    module Models
      module Options
        class ModelOptionManufacturer
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              name: {type: [:string, :null]},
              slug: {type: [:string, :null]},
              code: {type: [:string, :null]}
            },
            additionalProperties: false,
            required: %w[name slug code]
          })
        end
      end
    end
  end
end
