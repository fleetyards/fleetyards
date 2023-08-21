# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class ShopCommodity < ::V1::Schemas::ShopCommodity
        include SchemaConcern

        schema({
          properties: {
            submitter: {
              type: :object,
              properties: {
                id: {type: :string, format: :uuid},
                username: {type: :string}
              },
              required: %w[id username],
              additionalProperties: false
            }
          }
        })
      end
    end
  end
end
