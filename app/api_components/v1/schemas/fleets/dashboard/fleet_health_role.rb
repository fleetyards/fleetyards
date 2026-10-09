# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Dashboard
        class FleetHealthRole
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              name: {type: :string}
            },
            required: %w[id name]
          })
        end
      end
    end
  end
end
