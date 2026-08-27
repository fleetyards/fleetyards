# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Missions
        class MissionExtended
          include OpenapiRuby::Components::Base

          schema({
            allOf: [
              ::V1::Schemas::Fleets::Missions::Mission,
              {
                type: :object,
                properties: {
                  teams: {
                    type: :array,
                    items: ::V1::Schemas::Fleets::Missions::MissionTeam
                  }
                },
                required: %w[teams]
              }
            ]
          })
        end
      end
    end
  end
end
