# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelCrew
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            max: {type: :integer},
            maxLabel: {type: :string},
            min: {type: :integer},
            minLabel: {type: :string}
          },
          additionalProperties: false

        })
      end
    end
  end
end
