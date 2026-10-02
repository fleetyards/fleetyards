# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class LocationShop
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            hasImage: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[id name hasImage]
        })
      end
    end
  end
end
