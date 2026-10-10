# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      class ModelCrew
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            value: {type: :integer},
            label: {type: :string}
          },
          additionalProperties: false

        })
      end
    end
  end
end
