# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class FeatureActor
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            type: {type: :string},
            id: {type: :string},
            name: {type: :string}
          },
          additionalProperties: false,
          required: %w[type id name]
        })
      end
    end
  end
end
