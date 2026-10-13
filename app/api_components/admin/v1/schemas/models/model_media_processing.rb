# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      module Models
        # A background crop of one of a model's views settled. What is left in
        # `mediaProcessing` is still on its way.
        class ModelMediaProcessing
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              modelId: {type: :string, format: :uuid},
              mediaProcessing: {type: :array, items: {type: :string}}
            },
            additionalProperties: false,
            required: %w[modelId mediaProcessing]
          })
        end
      end
    end
  end
end
