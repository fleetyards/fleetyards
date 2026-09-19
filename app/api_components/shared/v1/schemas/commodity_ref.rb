# frozen_string_literal: true

module Shared
  module V1
    module Schemas
      # One commodity named from somewhere else in the catalogue. Nullable,
      # because every use of it so far is a link a commodity may not have.
      #
      # In `shared/v1` because the admin commodity payload subclasses the public
      # one and inherits every reference it makes.
      class CommodityRef
        include OpenapiRuby::Components::Base

        schema({
          type: [:object, :null],
          properties: {
            id: {type: :string, format: :uuid},
            name: {type: :string},
            slug: {type: :string}
          },
          additionalProperties: false,
          required: %w[id name slug]
        })
      end
    end
  end
end
