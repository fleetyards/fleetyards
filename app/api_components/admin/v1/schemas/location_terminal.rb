# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class LocationTerminal
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            available: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[id name available]
        })
      end
    end
  end
end
