# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Logistics
        class FleetInventoryManager
          include OpenapiRuby::Components::Base

          schema({
            type: :object,
            properties: {
              id: {type: :string, format: :uuid},
              username: {type: :string},
              rsiHandle: {type: :string},
              discordProfileUrl: {type: :string, format: :uri},
              citizenidProfileUrl: {type: :string, format: :uri}
            }
          })
        end
      end
    end
  end
end
