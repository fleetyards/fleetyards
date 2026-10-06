# frozen_string_literal: true

module V1
  module Schemas
    module Fleets
      module Squadrons
        class FleetSquadronRequestsList
          include OpenapiRuby::Components::Base

          schema({
            type: :array,
            items: ::V1::Schemas::Fleets::Squadrons::FleetSquadronRequest
          })
        end
      end
    end
  end
end
