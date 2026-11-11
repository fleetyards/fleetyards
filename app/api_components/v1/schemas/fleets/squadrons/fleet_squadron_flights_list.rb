# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronFlightsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Fleets::Squadrons::FleetSquadronFlight
          })
        end
      end
    end
  end
end
