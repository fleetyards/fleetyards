# frozen_string_literal: true

module Admin
  module V1
    module Schemas
      class Equipment < ::Shared::V1::Schemas::Equipment
        include OpenapiRuby::Components::Base

        schema({
          properties: {
            hidden: {type: :boolean},

            # The cheapest of `availability`, flattened out so the list can show
            # and filter by a price without reading down the terminal arrays.
            buyPrice: {type: [:number, :null]},
            sellPrice: {type: [:number, :null]},

            scKey: {type: [:string, :null]},
            scRef: {type: [:string, :null]},
            version: {type: [:string, :null]}
          },
          required: %w[hidden]
        })
      end
    end
  end
end
