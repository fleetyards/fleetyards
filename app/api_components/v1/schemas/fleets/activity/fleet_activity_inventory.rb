# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Activity
        class FleetActivityInventory
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              slug: {type: :string},
              name: {type: :string}
            },
            required: %w[id slug name]
          })
        end
      end
    end
  end
end
